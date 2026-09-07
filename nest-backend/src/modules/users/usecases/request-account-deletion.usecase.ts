import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AccountDeletionBlockedError, AppError, UserNotFoundError } from '@/shared/core/errors';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';
import { AccountDeletionState } from '../types/account.types';

export const ACCOUNT_DELETION_GRACE_DAYS = 30;

@Injectable()
export class RequestAccountDeletionUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly accountLifecycleRepository: AccountLifecycleDatabaseRepository,
    private readonly sessionRevoker: SessionRevokerService,
  ) {}

  async execute(input: { userId: string }): Promise<Either<AppError, AccountDeletionState>> {
    const userResult = await this.userRepository.findById(input.userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new UserNotFoundError());

    if (userResult.value.deletionRequestedAt) {
      return right(this.buildState(userResult.value.deletionRequestedAt));
    }

    const blockersResult = await this.accountLifecycleRepository.findDeletionBlockers(input.userId);
    if (blockersResult.isLeft()) return left(blockersResult.value);

    const blockers = blockersResult.value;
    const reasons: string[] = [];
    if (blockers.openOrdersAsBuyer > 0) {
      reasons.push(`${blockers.openOrdersAsBuyer} compra(s) em andamento`);
    }
    if (blockers.openOrdersAsSeller > 0) {
      reasons.push(`${blockers.openOrdersAsSeller} venda(s) em andamento`);
    }
    if (blockers.openDisputes > 0) {
      reasons.push(`${blockers.openDisputes} disputa(s) aberta(s)`);
    }
    if (blockers.walletBalance > 0) {
      reasons.push('saldo na carteira a receber');
    }
    if (reasons.length > 0) {
      return left(new AccountDeletionBlockedError(reasons));
    }

    const requestResult = await this.accountLifecycleRepository.requestDeletion(
      input.userId,
      new Date(),
    );
    if (requestResult.isLeft()) return left(requestResult.value);

    await this.sessionRevoker.revokeAllSessions(input.userId);

    return right(this.buildState(requestResult.value));
  }

  private buildState(requestedAt: Date): AccountDeletionState {
    const purgeAfter = new Date(requestedAt);
    purgeAfter.setDate(purgeAfter.getDate() + ACCOUNT_DELETION_GRACE_DAYS);
    return { deletionRequestedAt: requestedAt, purgeAfter };
  }
}
