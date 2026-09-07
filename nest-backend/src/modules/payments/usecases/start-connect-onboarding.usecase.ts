import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';
import { ConnectAccountRepository } from '../domain/repositories/connect-account.repository';

@Injectable()
export class StartConnectOnboardingUseCase {
  constructor(
    private readonly connectRepo: ConnectAccountRepository,
    private readonly stripe: StripeProvider,
    private readonly config: ConfigService,
  ) {}

  async execute(userId: string): Promise<Either<AppError, { onboardingUrl: string }>> {
    const existing = await this.connectRepo.findByUserId(userId);
    if (isLeft(existing)) return left(existing.value);

    let stripeAccountId = existing.value?.stripeAccountId;

    if (!stripeAccountId) {
      const contact = await this.connectRepo.findUserContact(userId);
      if (isLeft(contact)) return left(contact.value);
      if (!contact.value) return left(new NotFoundError('User'));

      const country = this.config.get<string>('CONNECT_ACCOUNT_COUNTRY', 'BR');
      const currency = this.config.get<string>('CONNECT_ACCOUNT_CURRENCY', 'brl');

      const created = await this.stripe.createConnectAccount({
        email: contact.value.email,
        displayName: contact.value.displayName,
        country,
        currency,
      });
      if (isLeft(created)) return left(created.value);

      const saved = await this.connectRepo.upsertFromSnapshot(userId, created.value);
      if (isLeft(saved)) return left(saved.value);

      stripeAccountId = created.value.stripeAccountId;
    }

    const host = this.config.get<string>('DEEP_LINK_HOST') ?? this.config.get<string>('APP_URL', '');
    const link = await this.stripe.createOnboardingLink(
      stripeAccountId,
      `${host}/wallet/connect/refresh`,
      `${host}/wallet/connect/return`,
    );
    if (isLeft(link)) return left(link.value);

    return right({ onboardingUrl: link.value });
  }
}
