import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';
import { ConnectStatusOutput } from '../dtos/connect.dto';

@Injectable()
export class GetConnectStatusUseCase {
  constructor(
    private readonly connectRepo: ConnectAccountDatabaseRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(userId: string): Promise<Either<AppError, ConnectStatusOutput>> {
    const stored = await this.connectRepo.findByUserId(userId);
    if (stored.isLeft()) return left(stored.value);

    if (!stored.value) {
      return right({
        status: 'onboarding-required',
        requirementsDue: [],
      });
    }

    const snapshot = await this.stripe.refreshConnectAccount(stored.value.stripeAccountId);
    if (snapshot.isLeft()) {
      return left(snapshot.value);
    }

    const saved = await this.connectRepo.upsertFromSnapshot(userId, snapshot.value);
    if (saved.isLeft()) return left(saved.value);

    return right({ status: snapshot.value.status, requirementsDue: snapshot.value.requirementsDue });
  }
}
