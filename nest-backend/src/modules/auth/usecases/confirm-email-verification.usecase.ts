import { Injectable } from '@nestjs/common';
import { createHash, timingSafeEqual } from 'node:crypto';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  EmailVerificationCodeAttemptsExceededError,
  EmailVerificationCodeNotFoundError,
} from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { UserResponse, toUserResponse } from '@/modules/users/dtos/user-response.class';
import {
  EMAIL_VERIFICATION_MAX_ATTEMPTS,
  EMAIL_VERIFICATION_TTL_SECONDS,
  emailVerificationAttemptsKey,
  emailVerificationCodeKey,
} from './request-email-verification.usecase';

@Injectable()
export class ConfirmEmailVerificationUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly redis: RedisService,
  ) {}

  async execute(userId: string, token: string): Promise<Either<AppError, { user: UserResponse; emailVerified: true }>> {
    if (!token) return left(new EmailVerificationCodeNotFoundError());

    const storedHash = await this.redis.get(emailVerificationCodeKey(userId));
    if (!storedHash) return left(new EmailVerificationCodeNotFoundError());

    const attempts = await this.redis.incrementWithExpiry(emailVerificationAttemptsKey(userId), EMAIL_VERIFICATION_TTL_SECONDS);
    if (attempts > EMAIL_VERIFICATION_MAX_ATTEMPTS) return left(new EmailVerificationCodeAttemptsExceededError());

    const tokenHash = createHash('sha256').update(token).digest('hex');
    const expected = Buffer.from(storedHash, 'hex');
    const received = Buffer.from(tokenHash, 'hex');
    if (expected.length !== received.length || !timingSafeEqual(expected, received)) {
      return left(new EmailVerificationCodeNotFoundError());
    }

    const updated = await this.userRepository.update(userId, { emailVerified: true });
    if (updated.isLeft()) return left(updated.value);

    await Promise.allSettled([
      this.redis.del(emailVerificationCodeKey(userId)),
      this.redis.del(emailVerificationAttemptsKey(userId)),
    ]);
    return right({ user: toUserResponse(updated.value, undefined, true), emailVerified: true });
  }
}
