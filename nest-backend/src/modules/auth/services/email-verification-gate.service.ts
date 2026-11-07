import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, EmailVerificationRequiredError, UserNotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';

/**
 * Single server-side gate for money actions and provider linking:
 * reads the current user and rejects unverified emails with a controlled error.
 */
@Injectable()
export class EmailVerificationGateService {
  constructor(private readonly users: UserDatabaseRepository) {}

  async ensureVerified(userId: string): Promise<Either<AppError, void>> {
    const result = await this.users.findById(userId);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new UserNotFoundError());
    return result.value.emailVerified ? right(undefined) : left(new EmailVerificationRequiredError());
  }
}
