import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountRepository } from '../domain/repositories/connect-account.repository';

@Injectable()
export class GetConnectDashboardLinkUseCase {
  constructor(
    private readonly connectRepo: ConnectAccountRepository,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(userId: string): Promise<Either<AppError, { dashboardUrl: string }>> {
    const stored = await this.connectRepo.findByUserId(userId);
    if (isLeft(stored)) return left(stored.value);
    if (!stored.value) return left(new NotFoundError('Connect account'));
    if (!stored.value.detailsSubmitted) {
      return left(new BadRequestError('Conclua o cadastro de recebimentos antes de abrir o painel'));
    }

    const link = await this.stripe.createDashboardLink(stored.value.stripeAccountId);
    if (isLeft(link)) return left(link.value);

    return right({ dashboardUrl: link.value });
  }
}
