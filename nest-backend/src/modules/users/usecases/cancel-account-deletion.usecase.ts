import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, FreshAuthenticationRequiredError, UserNotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';

export const DELETION_CANCEL_FRESH_AUTH_MS = 5 * 60 * 1000;

@Injectable()
export class CancelAccountDeletionUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly accountLifecycleRepository: AccountLifecycleDatabaseRepository,
  ) {}

  async execute(input: { userId: string; authenticatedAtMs?: number | null }): Promise<Either<AppError, void>> {
    const now = Date.now();
    if (typeof input.authenticatedAtMs !== 'number' || !Number.isFinite(input.authenticatedAtMs) ||
      input.authenticatedAtMs > now || now - input.authenticatedAtMs > DELETION_CANCEL_FRESH_AUTH_MS) {
      return left(new FreshAuthenticationRequiredError());
    }

    const userResult = await this.userRepository.findById(input.userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new UserNotFoundError());
    if (userResult.value.deletedAt) return left(new UserNotFoundError());

    if (!userResult.value.deletionRequestedAt) {
      return left(new BadRequestError('Nenhuma exclusão de conta pendente'));
    }

    const cancelResult = await this.accountLifecycleRepository.cancelDeletion(input.userId);
    if (cancelResult.isLeft()) return left(cancelResult.value);

    return right(undefined);
  }
}
