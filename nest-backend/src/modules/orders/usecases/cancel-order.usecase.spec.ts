import { Test } from '@nestjs/testing';
import { OrderDatabaseRepository } from '../data/repositories/order-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { Either, left, right } from '@/shared/core/either';
import { AppError, PaymentProviderError } from '@/shared/core/errors';
import { RefundSnapshot } from '@/modules/payments/types/payment-provider.types';
import { ChargeRefundSnapshot } from '@/modules/payments/types/payment-provider.types';
import { CancelOrderUseCase } from './cancel-order.usecase';

describe('CancelOrderUseCase money claims', () => {
  async function setup(
    refundResult: Either<AppError, RefundSnapshot> = right({
      id: 're_1', chargeId: 'ch_1', amount: 10000, status: 'succeeded', orderId: 'order-1', operationId: 'refund-op-1',
    }),
    claimResult: Either<AppError, boolean> = right(true),
  ) {
    const events: string[] = [];
    const orderRepository = {
      findById: jest.fn().mockResolvedValue(right({
        id: 'order-1', buyerId: 'buyer-1', sellerId: 'seller-1', productId: 'product-1',
        amount: 10000, sellerAmount: 9000, quantity: 1, status: 'CONFIRMED',
      })),
      claimCancellation: jest.fn(async () => { events.push('claim'); return claimResult; }),
      cancelOrder: jest.fn(async () => { events.push('finalize'); return right(true); }),
      refundOrder: jest.fn(async () => { events.push('finalize'); return right(true); }),
    };
    const transactions = {
      findByOrderId: jest.fn().mockResolvedValue(right({
        status: 'HELD', paymentGroupId: null, chargeId: 'ch_1', externalId: 'pi_1', transferId: null,
        idempotencyKey: 'payment-order-1',
      })),
      reserveRefund: jest.fn(async () => { events.push('reserve'); return right({ operationId: 'refund-op-1', idempotencyKey: 'refund:order-1', providerId: null, created: true }); }),
      recordRefundProviderId: jest.fn(async () => { events.push('persist'); return right(true); }),
    };
    const stripe = {
      retrieveChargeRefunds: jest.fn<Promise<Either<AppError, ChargeRefundSnapshot>>, []>(async () => {
        events.push('reconcile');
        return right({ id: 'ch_1', amount: 10000, amountRefunded: 0, refunds: [] });
      }),
      refundPayment: jest.fn(async () => { events.push('refund'); return refundResult; }),
    };
    const module = await Test.createTestingModule({
      providers: [
        CancelOrderUseCase,
        { provide: OrderDatabaseRepository, useValue: orderRepository },
        { provide: NotificationService, useValue: { create: jest.fn() } },
        { provide: TransactionDatabaseRepository, useValue: transactions },
        { provide: StripeProvider, useValue: stripe },
        { provide: SellerPayoutService, useValue: { reverseForOrder: jest.fn().mockResolvedValue(right(undefined)) } },
      ],
    }).compile();
    return { sut: module.get(CancelOrderUseCase), orderRepository, stripe, events };
  }

  it('claims cancellation before provider refund and finalizes only after success', async () => {
    const { sut, orderRepository, stripe, events } = await setup();

    const result = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'Changed mind' });

    expect(result.isRight()).toBe(true);
    expect(orderRepository.claimCancellation).toHaveBeenCalledWith(
      'order-1', 'CONFIRMED', 'Changed mind', { refundOperationId: 'refund-op-1' },
    );
    expect(stripe.refundPayment).toHaveBeenCalledTimes(1);
    expect(stripe.refundPayment).toHaveBeenCalledWith(expect.objectContaining({
      knownProviderId: null,
      allowCreate: true,
    }));
    expect(events).toEqual(['reconcile', 'reserve', 'claim', 'refund', 'persist', 'finalize']);
    expect(orderRepository.refundOrder).toHaveBeenCalledWith(expect.objectContaining({
      refundOperationId: 'refund-op-1', refundProviderId: 're_1', refundAmount: 10000,
    }));
  });

  it('strips C0/C1 controls before storing an accented cancellation reason', async () => {
    const { sut, orderRepository } = await setup();

    const result = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'Ação\u0000\u009f' });

    expect(result.isRight()).toBe(true);
    expect(orderRepository.claimCancellation).toHaveBeenCalledWith(
      'order-1', 'CONFIRMED', 'Ação', { refundOperationId: 'refund-op-1' },
    );
  });

  it('rejects a cancellation reason that becomes blank after control stripping', async () => {
    const { sut, orderRepository, stripe } = await setup();

    const result = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: '\u0000\u009f  ' });

    expect(result.isLeft()).toBe(true);
    expect(orderRepository.claimCancellation).not.toHaveBeenCalled();
    expect(stripe.refundPayment).not.toHaveBeenCalled();
  });

  it('does not call Stripe or report cancellation when the conditional claim is lost', async () => {
    const { sut, orderRepository, stripe } = await setup(right({
      id: 're_1', chargeId: 'ch_1', amount: 10000, status: 'succeeded', orderId: 'order-1', operationId: 'refund-op-1',
    }), right(false));

    const result = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'Changed mind' });

    expect(result.isLeft()).toBe(true);
    expect(orderRepository.cancelOrder).not.toHaveBeenCalled();
    expect(stripe.refundPayment).not.toHaveBeenCalled();
  });

  it('leaves the order held and its refund operation claimed when provider outcome is ambiguous', async () => {
    const { sut, orderRepository } = await setup(left(new PaymentProviderError('unavailable')));

    const result = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'Changed mind' });

    expect(result.isLeft()).toBe(true);
    expect(orderRepository.claimCancellation).toHaveBeenCalledWith(
      'order-1', 'CONFIRMED', 'Changed mind', { refundOperationId: 'refund-op-1' },
    );
    expect(orderRepository.refundOrder).not.toHaveBeenCalled();
  });

  it('can retry a provider lookup failure with a changed reason because no stale reason claim was persisted', async () => {
    const { sut, orderRepository, stripe } = await setup();
    stripe.retrieveChargeRefunds
      .mockResolvedValueOnce(left(new PaymentProviderError('provider lookup unavailable')))
      .mockResolvedValueOnce(right({ id: 'ch_1', amount: 10000, amountRefunded: 0, refunds: [] }));

    const failed = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'First reason' });
    const retried = await sut.execute({ orderId: 'order-1', userId: 'buyer-1', reason: 'Updated reason' });

    expect(failed.isLeft()).toBe(true);
    expect(retried.isRight()).toBe(true);
    expect(orderRepository.claimCancellation).toHaveBeenCalledTimes(1);
    expect(orderRepository.claimCancellation).toHaveBeenCalledWith(
      'order-1', 'CONFIRMED', 'Updated reason', { refundOperationId: 'refund-op-1' },
    );
  });
});
