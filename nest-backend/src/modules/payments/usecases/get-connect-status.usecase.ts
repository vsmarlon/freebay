import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountRepository } from '../domain/repositories/connect-account.repository';
import { ConnectStatusOutput } from '../dtos/connect.dto';

@Injectable()
export class GetConnectStatusUseCase {
  constructor(
    private readonly connectRepo: ConnectAccountRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(userId: string): Promise<Either<AppError, ConnectStatusOutput>> {
    const stored = await this.connectRepo.findByUserId(userId);
    if (isLeft(stored)) return left(stored.value);

    if (!stored.value) {
      return right({
        onboarded: false,
        transfersEnabled: false,
        payoutsEnabled: false,
        requirementsDue: [],
      });
    }

    const snapshot = await this.stripe.refreshConnectAccount(stored.value.stripeAccountId);
    if (isLeft(snapshot)) {
      return right({
        onboarded: stored.value.detailsSubmitted,
        transfersEnabled: stored.value.transfersEnabled,
        payoutsEnabled: stored.value.payoutsEnabled,
        requirementsDue: stored.value.requirementsDue,
      });
    }

    const saved = await this.connectRepo.upsertFromSnapshot(userId, snapshot.value);
    if (isLeft(saved)) return left(saved.value);

    return right({
      onboarded: saved.value.detailsSubmitted,
      transfersEnabled: saved.value.transfersEnabled,
      payoutsEnabled: saved.value.payoutsEnabled,
      requirementsDue: saved.value.requirementsDue,
    });
  }
}
