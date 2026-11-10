import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { ResendService } from '../services/resend.service';
import { dispatchAuthEmailJob } from '../utils/dispatch-auth-email-job';

export const EMAIL_VERIFICATION_TTL_SECONDS = 10 * 60;
export const EMAIL_VERIFICATION_RESEND_LIMIT = 3;
export const EMAIL_VERIFICATION_RESEND_WINDOW_SECONDS = 60 * 60;
export const EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS = 60;
export const EMAIL_VERIFICATION_MAX_ATTEMPTS = 5;

const codeKey = (userId: string) => `email-verification:code:${userId}`;
const attemptsKey = (userId: string) => `email-verification:attempts:${userId}`;
const requestsKey = (userId: string) => `email-verification:requests:${userId}`;
const cooldownKey = (userId: string) => `email-verification:cooldown:${userId}`;

export { codeKey as emailVerificationCodeKey, attemptsKey as emailVerificationAttemptsKey };

@Injectable()
export class RequestEmailVerificationUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly resend: ResendService,
    private readonly redis: RedisService,
  ) {}

  async execute(userId: string, locale: 'pt-BR' | 'en' = 'pt-BR'): Promise<Either<AppError, { sent: true }>> {
    // ponytail: silent saturation like password recovery — resend limit per user, 1h window.
    const requests = await this.redis.incrementWithExpiry(requestsKey(userId), EMAIL_VERIFICATION_RESEND_WINDOW_SECONDS);
    if (requests > EMAIL_VERIFICATION_RESEND_LIMIT) return right({ sent: true });
    if (!(await this.redis.setIfAbsent(cooldownKey(userId), '1', EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS))) {
      return right({ sent: true });
    }

    dispatchAuthEmailJob(async () => {
      const userResult = await this.userRepository.findById(userId);
      if (userResult.isLeft()) return;
      const user = userResult.value;
      if (!user || user.emailVerified) return;

      const token = randomBytes(32).toString('base64url');
      const tokenHash = createHash('sha256').update(token).digest('hex');
      await this.redis.add(codeKey(userId), tokenHash, EMAIL_VERIFICATION_TTL_SECONDS);
      await this.redis.del(attemptsKey(userId));

      let messageId: { id: string } | null;
      try {
        messageId = await this.resend.sendMagicLink(user.email, token, locale, `email-verification/${tokenHash}`);
      } catch {
        await this.releaseChallenge(userId);
        return;
      }
      if (!messageId) await this.releaseChallenge(userId);
    });
    return right({ sent: true });
  }

  private async releaseChallenge(userId: string): Promise<void> {
    await Promise.allSettled([this.redis.del(codeKey(userId)), this.redis.del(cooldownKey(userId))]);
  }
}
