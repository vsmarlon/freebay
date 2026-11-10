import { Test } from '@nestjs/testing';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { RefundSnapshot, RefundStatus } from '@/modules/payments/types/payment-provider.types';
import { Either, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { DisputeResolutionExecutionService } from '../services/dispute-resolution-execution.service';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { ResolveDisputeUseCase } from './resolve-dispute.usecase';

describe('ResolveDisputeUseCase buyer refunds', () => {
  const now = new Date();
  const dispute = {
    id: 'dispute-1',
    orderId: 'order-1',
    openedById: 'buyer-1',
    status: 'OPEN',
    reason: 'not received',
    buyerEvidence: null,
    sellerEvidence: null,
    resolution: null,
    resolvedAt: null,
    resolvedById: null,
    createdAt: now,
    expiresAt: now,
    order: {
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'product-1',
      quantity: 1,
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      status: 'DISPUTED',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      cancellationReason: null,
      createdAt: now,
      updatedAt: now,
    },
  };

  async function setup(refundResult: Either<AppError, RefundSnapshot> = right({
    id: 're_1', chargeId: 'ch_1', amount: 10000, status: RefundStatus.SUCCEEDED, orderId: 'order-1', operationId: 'refund-op-1',
  })) {
    const events: string[] = [];
    const transaction = {
      orderId: 'order-1',
      status: 'HELD',
      externalId: 'pi_1',
      chargeId: 'ch_1',
      paymentGroupId: null,
      transferId: null,
    };
    const disputeRepo = {
      findById: jest.fn().mockResolvedValue(right(dispute)),
      claimOrderForBuyerRefund: jest.fn(async () => {
        events.push('claim');
        return { count: 1 };
      }),
    };
    const execution = {
      finalizeBuyer: jest.fn(async () => {
        events.push('finalize');
      }),
    };
    const payout = { payoutForOrder: jest.fn() };
    const notification = { notifyDispute: jest.fn().mockResolvedValue(undefined) };
    const transactions = {
      findByOrderId: jest.fn().mockResolvedValue(right(transaction)),
      reserveRefund: jest.fn().mockResolvedValue(right({ operationId: 'refund-op-1', idempotencyKey: 'refund:order-1', providerId: null, created: true })),
      recordRefundProviderId: jest.fn().mockResolvedValue(right(true)),
    };
    const stripe = {
      retrieveChargeRefunds: jest.fn(async () => {
        events.push('reconcile');
        return right({ id: 'ch_1', amount: 10000, amountRefunded: 0, refunds: [] });
      }),
      refundPayment: jest.fn(async () => {
        events.push('refund');
        return refundResult;
      }),
    };

    const module = await Test.createTestingModule({
      providers: [
        ResolveDisputeUseCase,
        { provide: DisputeDatabaseRepository, useValue: disputeRepo },
        { provide: NotificationService, useValue: notification },
        { provide: DisputeTransitionPolicy, useValue: { canResolve: () => true } },
        { provide: DisputeResolutionExecutionService, useValue: execution },
        { provide: SellerPayoutService, useValue: payout },
        { provide: StripeProvider, useValue: stripe },
        { provide: TransactionDatabaseRepository, useValue: transactions },
      ],
    }).compile();

    return {
      sut: module.get(ResolveDisputeUseCase),
      events,
      refundPayment: stripe.refundPayment,
      execution,
    };
  }

  it('refunds through Stripe before resolving or releasing the held dispute', async () => {
    const { sut, events, refundPayment, execution } = await setup();

    const result = await sut.execute({
      disputeId: 'dispute-1',
      resolution: 'Buyer wins',
      winner: 'BUYER',
    });

    expect(result.isRight()).toBe(true);
    expect(refundPayment).toHaveBeenCalledWith({
      orderId: 'order-1',
      amount: 10000,
      chargeId: 'ch_1',
      paymentIntentId: 'pi_1',
      operationId: 'refund-op-1',
      idempotencyKey: 'refund:order-1',
      knownProviderId: null,
      allowCreate: true,
    });
    expect(events).toEqual(['claim', 'reconcile', 'refund', 'finalize']);
    expect(execution.finalizeBuyer).toHaveBeenCalledTimes(1);
  });

  it('keeps the dispute held when Stripe cannot confirm the refund', async () => {
    const { sut, refundPayment, execution } = await setup(left(new DatabaseError('provider unavailable')));

    const result = await sut.execute({
      disputeId: 'dispute-1',
      resolution: 'Buyer wins',
      winner: 'BUYER',
    });

    expect(result.isLeft()).toBe(true);
    expect(refundPayment).toHaveBeenCalledTimes(1);
    expect(execution.finalizeBuyer).not.toHaveBeenCalled();
  });
});
