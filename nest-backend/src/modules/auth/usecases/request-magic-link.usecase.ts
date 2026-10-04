import { Injectable, Logger } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ResendService } from '../services/resend.service';
import { RequestMagicLinkDTO } from '../dtos/magic-link.dto';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { normalizeEmail } from '../utils/normalize-email';

export const MAGIC_LINK_THROTTLE_TTL_SECONDS = 60 * 60;
export const MAGIC_LINK_TTL_SECONDS = 10 * 60;

export class RequestMagicLinkInput extends RequestMagicLinkDTO {
  ip: string;
  userAgent?: string;
  returnOrigin?: string;
}

@Injectable()
export class RequestMagicLinkUseCase {
  private readonly logger = new Logger(RequestMagicLinkUseCase.name);

  constructor(
    private readonly repository: MagicLinkRepository,
    private readonly redis: RedisService,
    private readonly resend: ResendService,
  ) {}

  async execute(input: RequestMagicLinkInput): Promise<Either<AppError, { sent: true }>> {
    const email = normalizeEmail(input.email);
    const [emailCount, ipCount] = await Promise.all([
      this.redis.incrementWithExpiry(`magic-link:email:${email}`, MAGIC_LINK_THROTTLE_TTL_SECONDS),
      this.redis.incrementWithExpiry(`magic-link:ip:${input.ip}`, MAGIC_LINK_THROTTLE_TTL_SECONDS),
    ]);
    if (emailCount > 5 || ipCount > 20) return right({ sent: true });

    const token = input.purpose === 'account-deletion'
      ? `delete.${randomBytes(32).toString('base64url')}`
      : randomBytes(32).toString('base64url');
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const now = new Date();
    const created = await this.repository.create({
      email,
      tokenHash,
      consentGranted: input.consent,
      consentAt: input.consent ? now : null,
      requestedAt: now,
      activatedAt: now,
      expiresAt: new Date(now.getTime() + MAGIC_LINK_TTL_SECONDS * 1000),
      requestedIp: input.ip,
      userAgent: input.userAgent,
    });
    if (created.isLeft()) return left(created.value);

    try {
      const sent = await this.resend.sendMagicLink(email, token, input.locale, created.value.id, input.purpose, input.returnOrigin);
      if (sent) {
        const recorded = await this.repository.recordSendAccepted(created.value.id, new Date(), sent.id);
        if (recorded.isLeft()) this.logger.warn('Magic-link send metadata could not be recorded');
      }
    } catch {
      this.logger.warn('Magic-link provider request failed');
    }
    return right({ sent: true });
  }
}
