import { Test } from '@nestjs/testing';
import { Either, left, right } from '@/shared/core/either';
import { AppError, PaymentProviderError } from '@/shared/core/errors';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { SellerPayoutService } from '../services/seller-payout.service';
import { StripeProvider } from '../providers/stripe-provider';
import { ProcessRefundUseCase } from './process-refund.usecase';

describe('ProcessRefundUseCase', () => {
  function buildTransaction() {
    return {
      id: 'tx-1', orderId: 'order-1', status: 'HELD', chargeId: 'ch_1', transferId: null,
      refundOperationId: 'operation-1', refundAmount: 1000, refundProviderId: null,
      order: {
        id: 'order-1', productId: 'product-1', buyerId: 'buyer-1', amount: 1000,
        status: 'DISPUTED', escrowStatus: 'HELD', quantity: 1,
        sellerId: 'seller-1', sellerAmount: 900, cancellationReason: 'DISPUTE_REFUND_PENDING',
      },
    };
  }

  function buildRefund(status: 'succeeded' | 'pending' | 'requires_action' | 'failed' | 'canceled' | 'unknown' = 'succeeded') {
    return { id: 're-1', chargeId: 'ch_1', amount: 1000, status, orderId: 'order-1', operationId: 'operation-1' };
  }

  async function setup(refund = buildRefund()) {
    const events: string[] = [];
    const transactionRepo = {
      findByChargeId: jest.fn().mockResolvedValue(right(buildTransaction())),
      findByOrderId: jest.fn().mockResolvedValue(right(buildTransaction())),
      findPendingRefundRecoveries: jest.fn().mockResolvedValue(right([])),
      recordRefundProviderId: jest.fn(async () => { events.push('record'); return right(true); }),
    };
    const orderRepo = {
      refundOrder: jest.fn<Promise<Either<AppError, boolean>>, [unknown]>(async () => {
        events.push('finalize');
        return right(true);
      }),
    };
    const reverseForOrder = jest.fn<Promise<Either<AppError, void>>, []>(async () => {
      events.push('reverse');
      return right(undefined);
    });
    const payoutService = { reverseForOrder };
    const stripe = {
      retrieveChargeRefunds: jest.fn(async () => {
        events.push('provider');
        return right({ id: 'ch_1', amount: 1000, amountRefunded: 1000, refunds: [refund] });
      }),
      retrieveRefund: jest.fn(async () => right(refund)),
    };
    const module = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: OrderDatabaseRepository, useValue: orderRepo },
        { provide: SellerPayoutService, useValue: payoutService },
        { provide: StripeProvider, useValue: stripe },
      ],
    }).compile();
    return { sut: module.get(ProcessRefundUseCase), transactionRepo, orderRepo, payoutService, stripe, events };
  }

  it('finalizes only the order attributed by matching operation metadata after canonical Stripe success', async () => {
    const { sut, orderRepo, payoutService, events } = await setup();

    const result = await sut.execute('ch_1');

    expect(result.isRight()).toBe(true);
    expect(payoutService.reverseForOrder).toHaveBeenCalledWith('order-1');
    expect(orderRepo.refundOrder).toHaveBeenCalledWith(expect.objectContaining({
      orderId: 'order-1', amount: 1000, refundOperationId: 'operation-1', refundProviderId: 're-1',
    }));
    expect(events).toEqual(['provider', 'record', 'reverse', 'finalize']);
  });

  it.each(['pending', 'requires_action'] as const)('keeps %s refunds held and unresolved', async (status) => {
    const { sut, orderRepo } = await setup(buildRefund(status));

    const result = await sut.execute('ch_1');

    expect(result.isRight()).toBe(true);
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it('does not finalize a partial provider refund against a full-order allocation', async () => {
    const partial = { ...buildRefund(), amount: 400 };
    const { sut, orderRepo } = await setup(partial);

    const result = await sut.execute('ch_1');

    expect(result.isRight()).toBe(true);
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it('does not attribute a refund with mismatched operation metadata to an order', async () => {
    const unbound = { ...buildRefund(), operationId: 'other-operation' };
    const { sut, orderRepo, transactionRepo } = await setup(unbound);

    const result = await sut.execute('ch_1');

    expect(result.isRight()).toBe(true);
    expect(transactionRepo.recordRefundProviderId).not.toHaveBeenCalled();
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it('leaves the order held when seller transfer reversal fails', async () => {
    const { sut, orderRepo, payoutService } = await setup();
    payoutService.reverseForOrder.mockImplementation(async () => left(new PaymentProviderError('reversal unavailable')));

    const result = await sut.execute('ch_1');

    expect(result.isLeft()).toBe(true);
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it('recovers by persisted provider refund ID after provider success and local finalization failure', async () => {
    const { sut, stripe, orderRepo, transactionRepo } = await setup();
    transactionRepo.findPendingRefundRecoveries.mockResolvedValue(right([
      { orderId: 'order-1', chargeId: 'ch_1', refundProviderId: 're-1' },
    ]));
    orderRepo.refundOrder
      .mockResolvedValueOnce(left<AppError, boolean>(new PaymentProviderError('database unavailable')))
      .mockResolvedValueOnce(right(true));

    await sut.recoverPendingRefunds();
    await sut.recoverPendingRefunds();

    expect(stripe.retrieveRefund).toHaveBeenCalledTimes(2);
    expect(orderRepo.refundOrder).toHaveBeenCalledTimes(2);
  });
});
