import { Test, TestingModule } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { PaymentProviderError } from '@/shared/core/errors';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';
import { StripeProvider } from '../providers/stripe-provider';
import { GetConnectStatusUseCase } from './get-connect-status.usecase';

describe('GetConnectStatusUseCase', () => {
  it('does not present cached status when Stripe refresh fails', async () => {
    const connectRepo = {
      findByUserId: jest.fn().mockResolvedValue(
        right({
          stripeAccountId: 'acct_1',
          status: 'transfer-ready',
          detailsSubmitted: true,
          transfersEnabled: true,
          payoutsEnabled: true,
          requirementsDue: [],
        }),
      ),
      upsertFromSnapshot: jest.fn(),
    };
    const stripe = {
      refreshConnectAccount: jest.fn().mockResolvedValue(
        left(new PaymentProviderError()),
      ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetConnectStatusUseCase,
        { provide: ConnectAccountDatabaseRepository, useValue: connectRepo },
        { provide: StripeProvider, useValue: stripe },
      ],
    }).compile();

    const result = await module.get(GetConnectStatusUseCase).execute('user-1');

    expect(result.isLeft()).toBe(true);
    expect(connectRepo.upsertFromSnapshot).not.toHaveBeenCalled();
  });

  it('returns onboarding-required without a linked account', async () => {
    const connectRepo = {
      findByUserId: jest.fn().mockResolvedValue(right(null)),
      upsertFromSnapshot: jest.fn(),
    };
    const stripe = { refreshConnectAccount: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        GetConnectStatusUseCase,
        { provide: ConnectAccountDatabaseRepository, useValue: connectRepo },
        { provide: StripeProvider, useValue: stripe },
      ],
    }).compile();

    const result = await module.get(GetConnectStatusUseCase).execute('user-1');

    expect(result).toEqual(right({ status: 'onboarding-required', requirementsDue: [] }));
    expect(stripe.refreshConnectAccount).not.toHaveBeenCalled();
  });
});
