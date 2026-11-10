import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'node:crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { RequestStepUpMagicLinkDTO } from '../dtos/magic-link.dto';
import { MAGIC_LINK_THROTTLE_TTL_SECONDS } from './request-magic-link.usecase';
import { normalizeEmail } from '@/shared/utils/normalize-email';
import { isValidStepUpResource, signStepUpMagicContext } from '../utils/step-up-magic-context';
import { ResendService } from '../services/resend.service';

export type RequestWebStepUpMagicLinkInput = {
  user: AuthUser;
  body: RequestStepUpMagicLinkDTO;
  ip: string;
  userAgent?: string;
};

@Injectable()
export class RequestWebStepUpMagicLinkUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly magicLinks: MagicLinkRepository,
    private readonly redis: RedisService,
    private readonly resend: ResendService,
    private readonly config: ConfigService,
  ) {}

  async execute(input: RequestWebStepUpMagicLinkInput): Promise<Either<AppError, { sent: true }>> {
    if (!isValidStepUpResource(input.body.purpose, input.body.resourceId)) return right({ sent: true });

    const current = await this.users.findById(input.user.userId);
    if (current.isLeft()) return left(current.value);
    const user = current.value;
    const sessionStartedAtMs = input.user.sessionStartedAtMs;
    if (!user || user.suspendedAt || user.deletedAt || !user.email ||
      typeof sessionStartedAtMs !== 'number' || !Number.isSafeInteger(sessionStartedAtMs) ||
      (user.sessionsInvalidBefore && sessionStartedAtMs <= user.sessionsInvalidBefore.getTime())) {
      return right({ sent: true });
    }

    const email = normalizeEmail(user.email);
    const [emailCount, ipCount] = await Promise.all([
      this.redis.incrementWithExpiry(`magic-link:email:${email}`, MAGIC_LINK_THROTTLE_TTL_SECONDS),
      this.redis.incrementWithExpiry(`magic-link:ip:${input.ip}`, MAGIC_LINK_THROTTLE_TTL_SECONDS),
    ]);
    if (emailCount > 5 || ipCount > 20) return right({ sent: true });

    const token = `stepup.${randomBytes(32).toString('base64url')}`;
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const contextSignature = signStepUpMagicContext(this.config.getOrThrow<string>('JWT_SECRET'), {
      userId: user.id,
      purpose: input.body.purpose,
      resourceId: input.body.resourceId,
      tokenHash,
    });
    const now = new Date();
    const created = await this.magicLinks.create({
      email,
      tokenHash,
      consentGranted: false,
      consentAt: null,
      requestedAt: now,
      activatedAt: now,
      expiresAt: new Date(now.getTime() + 10 * 60 * 1000),
      requestedIp: input.ip,
      userAgent: input.userAgent,
    });
    if (created.isLeft()) return left(created.value);

    try {
      const sent = await this.resend.sendStepUpMagicLink(
        email, token, contextSignature, input.body.purpose, input.body.resourceId, input.body.locale, created.value.id,
      );
      if (sent) await this.magicLinks.recordSendAccepted(created.value.id, new Date(), sent.id);
    } catch {
      // Keep provider delivery failure non-enumerating; the action remains unverified.
    }
    return right({ sent: true });
  }
}
