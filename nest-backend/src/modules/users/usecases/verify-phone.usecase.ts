import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  PhoneCodeAlreadyUsedError,
  PhoneCodeAttemptsExceededError,
  PhoneCodeExpiredError,
  PhoneCodeNotFoundError,
} from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PhoneVerificationDatabaseRepository } from '../data/repositories/phone-verification-database.repository';
import { UserResponse, toUserResponse } from '../dtos/user-response.class';

export interface VerifyPhoneInput {
  userId: string;
  code: string;
}

@Injectable()
export class VerifyPhoneUseCase {
  constructor(
    private readonly phoneVerificationRepository: PhoneVerificationDatabaseRepository,
    private readonly prisma: PrismaService,
  ) {}

  async execute(input: VerifyPhoneInput): Promise<Either<AppError, UserResponse>> {
    const verificationResult = await this.phoneVerificationRepository.findLatestByUserId(input.userId);
    if (verificationResult.isLeft()) return left(verificationResult.value);
    const verification = verificationResult.value;

    if (!verification) {
      return left(new PhoneCodeNotFoundError());
    }

    if (verification.usedAt) {
      return left(new PhoneCodeAlreadyUsedError());
    }

    if (verification.expiresAt <= new Date()) {
      return left(new PhoneCodeExpiredError());
    }

    if (verification.attempts >= verification.maxAttempts) {
      return left(new PhoneCodeAttemptsExceededError());
    }

    const matches = await bcrypt.compare(input.code.trim(), verification.codeHash);
    if (!matches) {
      const attemptResult = await this.phoneVerificationRepository.reserveFailedAttempt(verification.id);
      if (attemptResult.isLeft()) return left(attemptResult.value);
      if (!attemptResult.value) return left(new PhoneCodeAttemptsExceededError());
      return left(new PhoneCodeNotFoundError());
    }

    const updateResult = await this.phoneVerificationRepository.consumeAndVerify(verification.id, input.userId);
    if (updateResult.isLeft()) return left(updateResult.value);
    if (!updateResult.value) return left(new PhoneCodeAlreadyUsedError());

    const [postsCount, productsCount, activeStory] = await Promise.all([
      this.prisma.post.count({ where: { userId: input.userId } }),
      this.prisma.product.count({
        where: { sellerId: input.userId, status: { not: 'DELETED' } },
      }),
      this.prisma.story.findFirst({
        where: { userId: input.userId, expiresAt: { gt: new Date() } },
        select: { id: true },
      }),
    ]);

    return right(
      toUserResponse(updateResult.value, {
        postsCount,
        productsCount,
        hasActiveStory: activeStory !== null,
      }, true),
    );
  }
}
