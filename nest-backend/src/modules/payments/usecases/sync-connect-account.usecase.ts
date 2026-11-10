import { Injectable, Logger } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';

@Injectable()
export class SyncConnectAccountUseCase {
  private readonly logger = new Logger(SyncConnectAccountUseCase.name);

  constructor(
    private readonly connectRepo: ConnectAccountDatabaseRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(stripeAccountId: string): Promise<Either<AppError, { processed: boolean }>> {
    const stored = await this.connectRepo.findByStripeAccountId(stripeAccountId);
    if (stored.isLeft() || !stored.value) {
      this.logger.warn(`Connect account ${stripeAccountId} is not linked to any user`);
      return right({ processed: false });
    }

    const snapshot = await this.stripe.refreshConnectAccount(stripeAccountId);
    if (snapshot.isLeft()) return right({ processed: false });

    const saved = await this.connectRepo.upsertFromSnapshot(stored.value.userId, snapshot.value);
    if (saved.isLeft()) return right({ processed: false });

    return right({ processed: true });
  }
}
