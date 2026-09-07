import { Injectable, Logger } from '@nestjs/common';
import { Either, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountRepository } from '../domain/repositories/connect-account.repository';

@Injectable()
export class SyncConnectAccountUseCase {
  private readonly logger = new Logger(SyncConnectAccountUseCase.name);

  constructor(
    private readonly connectRepo: ConnectAccountRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(stripeAccountId: string): Promise<Either<AppError, { processed: boolean }>> {
    const stored = await this.connectRepo.findByStripeAccountId(stripeAccountId);
    if (isLeft(stored) || !stored.value) {
      this.logger.warn(`Connect account ${stripeAccountId} is not linked to any user`);
      return right({ processed: false });
    }

    const snapshot = await this.stripe.refreshConnectAccount(stripeAccountId);
    if (isLeft(snapshot)) return right({ processed: false });

    const saved = await this.connectRepo.upsertFromSnapshot(stored.value.userId, snapshot.value);
    if (isLeft(saved)) return right({ processed: false });

    return right({ processed: true });
  }
}
