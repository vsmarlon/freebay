import { Test } from '@nestjs/testing';
import { Either, right, left } from '@/shared/core/either';
import { PaymentProviderError } from '@/shared/core/errors';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { ConnectAccountDatabaseRepository } from '../data/repositories/connect-account-database.repository';
import { StripeProvider } from '../providers/stripe-provider';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { SellerPayoutService } from './seller-payout.service';

type PayoutTransaction = {
  transferId: string | null;
  transferState: 'PENDING' | 'SUCCEEDED';
  transferIdempotencyKey: string;
  paymentGroupId: string | null;
  chargeId: string | null;
  id: string;
  sellerAmount: number;
  order: { sellerId: string };
  reversalState?: 'PENDING' | 'SUCCEEDED';
  reversalIdempotencyKey?: string;
  reversalId?: string | null;
};

const transaction: PayoutTransaction = {
  transferId: null,
  transferState: 'PENDING' as const,
  transferIdempotencyKey: 'transfer:transaction-1',
  paymentGroupId: null,
  chargeId: 'ch_1',
  id: 'transaction-1',
  sellerAmount: 1000,
  order: { sellerId: 'seller-1' },
};

const snapshot = (status: 'onboarding-required' | 'requirements-due' | 'restricted' | 'transfer-ready') => ({
  stripeAccountId: 'acct_1',
  country: 'BR',
  defaultCurrency: 'brl',
  status,
  transfersEnabled: status === 'transfer-ready',
  payoutsEnabled: status === 'transfer-ready',
  detailsSubmitted: status !== 'onboarding-required',
  requirementsDue: [],
});

describe('SellerPayoutService', () => {
  async function createService(
    status: 'onboarding-required' | 'requirements-due' | 'restricted' | 'transfer-ready',
    upsert: Either<PaymentProviderError, object> = right({}),
    currentTransaction: PayoutTransaction = transaction,
  ) {
    const transactionRepo = {
      findByOrderId: jest.fn().mockResolvedValue(right(currentTransaction)),
      claimTransfer: jest.fn().mockResolvedValue(right({ count: 1 })),
      finalizeTransfer: jest.fn().mockResolvedValue(right({ count: 1 })),
      markTransferFailure: jest.fn().mockResolvedValue(right({ count: 1 })),
      claimReversal: jest.fn().mockResolvedValue(right({ count: 1 })),
      finalizeReversal: jest.fn().mockResolvedValue(right({ count: 1 })),
      markReversalFailure: jest.fn().mockResolvedValue(right({ count: 1 })),
    };
    const connectRepo = {
      findByUserId: jest.fn().mockResolvedValue(right({
        stripeAccountId: 'acct_1',
        defaultCurrency: 'brl',
        transfersEnabled: true,
      })),
      upsertFromSnapshot: jest.fn().mockResolvedValue(upsert),
    };
    const stripe = {
      refreshConnectAccount: jest.fn().mockResolvedValue(right(snapshot(status))),
      createTransfer: jest.fn().mockResolvedValue(right('tr_1')),
      findTransfer: jest.fn().mockResolvedValue(right(null)),
      findReversal: jest.fn().mockResolvedValue(right(null)),
      reverseTransfer: jest.fn().mockResolvedValue(right('rev_1')),
    };
    const prisma = { $transaction: jest.fn().mockResolvedValue(undefined) };
    const module = await Test.createTestingModule({
      providers: [
        SellerPayoutService,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: ConnectAccountDatabaseRepository, useValue: connectRepo },
        { provide: StripeProvider, useValue: stripe },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    return { service: module.get(SellerPayoutService), stripe, connectRepo, transactionRepo };
  }

  it.each([
    'onboarding-required',
    'requirements-due',
    'restricted',
  ] as const)('does not transfer for fresh %s', async (status) => {
    const { service, stripe } = await createService(status);

    await service.payoutForOrder('order-1');

    expect(stripe.createTransfer).not.toHaveBeenCalled();
  });

  it('does not trust a cached ready projection when Stripe is freshly restricted', async () => {
    const { service, stripe } = await createService('restricted');

    await service.payoutForOrder('order-1');

    expect(stripe.refreshConnectAccount).toHaveBeenCalledWith('acct_1');
    expect(stripe.createTransfer).not.toHaveBeenCalled();
  });

  it('transfers when a cached false projection is freshly transfer-ready', async () => {
    const { service, stripe } = await createService('transfer-ready');

    await service.payoutForOrder('order-1');

    expect(stripe.createTransfer).toHaveBeenCalledWith({
      amount: 1000,
      currency: 'brl',
      destination: 'acct_1',
      sourceTransaction: 'ch_1',
      orderId: 'order-1',
      transactionId: 'transaction-1',
      transferGroup: 'freebay:order:order-1',
      idempotencyKey: 'transfer:transaction-1',
    });
  });

  it('does not transfer when refresh fails or snapshot persistence fails', async () => {
    const refreshed = await createService('transfer-ready', left(new PaymentProviderError()));
    refreshed.stripe.refreshConnectAccount.mockResolvedValue(left(new PaymentProviderError()));
    await refreshed.service.payoutForOrder('order-1');
    expect(refreshed.stripe.createTransfer).not.toHaveBeenCalled();

    const failedUpsert = await createService('transfer-ready', left(new PaymentProviderError()));
    await failedUpsert.service.payoutForOrder('order-1');
    expect(failedUpsert.stripe.createTransfer).not.toHaveBeenCalled();
  });

  it('persists a terminal state for a non-retryable provider rejection', async () => {
    const { service, stripe, connectRepo, transactionRepo } = await createService('transfer-ready');
    const rejection = new PaymentProviderError('invalid destination', 400);
    stripe.createTransfer.mockResolvedValue(left(rejection));

    await service.payoutForOrder('order-1');

    expect(connectRepo.upsertFromSnapshot).toHaveBeenCalled();
    expect(transactionRepo.markTransferFailure).toHaveBeenCalledWith(
      'transaction-1',
      'TERMINAL',
      'invalid destination',
    );
  });

  it('persists a retryable state for a rate-limited provider rejection', async () => {
    const { service, stripe, transactionRepo } = await createService('transfer-ready');
    stripe.createTransfer.mockResolvedValue(left(new PaymentProviderError('rate limited', 429)));

    await service.payoutForOrder('order-1');

    expect(transactionRepo.markTransferFailure).toHaveBeenCalledWith(
      'transaction-1',
      'RETRYABLE',
      'rate limited',
    );
  });

  it('keeps processing when transfer reconciliation has an unknown outcome', async () => {
    const { service, stripe, transactionRepo } = await createService('transfer-ready');
    stripe.findTransfer.mockResolvedValue(left(new PaymentProviderError('timeout', 500)));

    await service.payoutForOrder('order-1');

    expect(transactionRepo.markTransferFailure).not.toHaveBeenCalled();
    expect(stripe.createTransfer).not.toHaveBeenCalled();
  });

  it.each([
    [400, 'TERMINAL'],
    [429, 'RETRYABLE'],
  ] as const)('classifies reversal provider status %s as %s', async (status, expectedState) => {
    const reversalTransaction = {
      ...transaction,
      transferId: 'tr_1',
      reversalState: 'PENDING' as const,
      reversalIdempotencyKey: 'reversal:transaction-1',
    };
    const { service, stripe, transactionRepo } = await createService('transfer-ready', right({}), reversalTransaction);
    stripe.reverseTransfer.mockResolvedValue(left(new PaymentProviderError('reversal failed', status)));

    await service.reverseForOrder('order-1');

    expect(transactionRepo.markReversalFailure).toHaveBeenCalledWith(
      'transaction-1',
      expectedState,
      'reversal failed',
    );
  });

  it('keeps reversal processing when reconciliation has an unknown outcome', async () => {
    const reversalTransaction = {
      ...transaction,
      transferId: 'tr_1',
      reversalState: 'PENDING' as const,
      reversalIdempotencyKey: 'reversal:transaction-1',
    };
    const { service, stripe, transactionRepo } = await createService('transfer-ready', right({}), reversalTransaction);
    stripe.findReversal.mockResolvedValue(left(new PaymentProviderError('timeout', 500)));

    await service.reverseForOrder('order-1');

    expect(transactionRepo.markReversalFailure).not.toHaveBeenCalled();
    expect(stripe.reverseTransfer).not.toHaveBeenCalled();
  });
});
