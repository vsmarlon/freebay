import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';

@Injectable()
export class GetConnectDashboardLinkUseCase {
  constructor(
    private readonly connectRepo: ConnectAccountDatabaseRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(userId: string): Promise<Either<AppError, { dashboardUrl: string }>> {
    const stored = await this.connectRepo.findByUserId(userId);
    if (stored.isLeft()) return left(stored.value);
    if (!stored.value) return left(new NotFoundError('Connect account'));
    const link = await this.stripe.createDashboardLink(stored.value.stripeAccountId);
    if (link.isLeft()) return left(link.value);

    return right({ dashboardUrl: link.value });
  }
}
