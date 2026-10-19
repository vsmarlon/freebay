import { Injectable } from '@nestjs/common';
import { TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, DatabaseError, ConflictError, PaymentProviderError } from '@/shared/core/errors';
import { NotificationService } from '../../notifications/services/notification.service';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from '../services/dispute-resolution-execution.service';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { DisputeWinner } from '../dispute.constants';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';

const BUYER_REFUND_PENDING = 'DISPUTE_REFUND_PENDING';

@Injectable()
export class ResolveDisputeUseCase {
  constructor(
    private disputeRepo: DisputeDatabaseRepository,
    private notificationService: NotificationService,
    private transitionPolicy: DisputeTransitionPolicy,
    private resolutionExecution: DisputeResolutionExecutionService,
    private payoutService: SellerPayoutService,
    private transactionRepo: TransactionDatabaseRepository,
    private stripe: StripeProvider,
  ) {}

  async execute(input: {
    disputeId: string;
    resolution: string;
    winner: 'BUYER' | 'SELLER';
    resolvedById?: string;
  }): Promise<Either<AppError, void>> {
    const disputeResult = await this.disputeRepo.findById(input.disputeId);
    if (disputeResult.isLeft()) return left(disputeResult.value);

    const dispute = disputeResult.value;
    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    if (!this.transitionPolicy.canResolve(dispute.status)) {
      return left(new BadRequestError(`Dispute cannot be resolved while it is ${dispute.status}`));
    }

    if (input.winner === DisputeWinner.BUYER) {
      const transactionResult = await this.transactionRepo.findByOrderId(dispute.orderId);
      if (transactionResult.isLeft()) return left(transactionResult.value);
      const transaction = transactionResult.value;
      if (!transaction || !transaction.chargeId ||
          (transaction.status !== TransactionStatus.PAID &&
           transaction.status !== TransactionStatus.HELD &&
           transaction.status !== TransactionStatus.RELEASED)) {
        return left(new PaymentProviderError('Pagamento sem cobrança reconciliável'));
      }

      const claimed = await this.disputeRepo.claimOrderForBuyerRefund(dispute.orderId, BUYER_REFUND_PENDING);
      if (claimed.count === 0) return left(new ConflictError('Order is already being canceled, released or resolved'));

      if (transaction.transferId) {
        const reversed = await this.payoutService.reverseForOrder(dispute.orderId);
        if (reversed.isLeft()) return left(reversed.value);
      }

      const canonical = await this.stripe.retrieveChargeRefunds(transaction.chargeId);
      if (canonical.isLeft()) return left(canonical.value);
      const reserved = await this.transactionRepo.reserveRefund(dispute.orderId, dispute.order.amount, canonical.value);
      if (reserved.isLeft()) return left(reserved.value);
      const refund = await this.stripe.refundPayment({
        orderId: dispute.orderId,
        amount: dispute.order.amount,
        chargeId: transaction.chargeId,
        paymentIntentId: transaction.externalId?.startsWith('pi_') ? transaction.externalId : undefined,
        operationId: reserved.value.operationId,
        idempotencyKey: reserved.value.idempotencyKey,
        knownProviderId: reserved.value.providerId,
        allowCreate: reserved.value.created,
      });
      if (refund.isLeft()) return left(refund.value);
      const recorded = await this.transactionRepo.recordRefundProviderId(dispute.orderId, reserved.value.operationId, refund.value.id);
      if (recorded.isLeft()) return left(recorded.value);
      if (!recorded.value) return left(new ConflictError('Refund identity requires manual reconciliation'));
      if (refund.value.status !== 'succeeded') {
        return left(new PaymentProviderError('Refund remains pending; dispute is held for reconciliation'));
      }

      try {
        await this.resolutionExecution.finalizeBuyer(dispute, {
          operationId: reserved.value.operationId,
          providerId: refund.value.id,
          amount: refund.value.amount,
        }, {
          resolution: input.resolution,
          resolvedById: input.resolvedById ?? null,
        });
      } catch (error) {
        if (error instanceof Error && error.message === 'DISPUTE_NOT_RESOLVABLE') {
          return left(new BadRequestError('Dispute cannot be resolved while it is not open'));
        }
        return left(new DatabaseError('Failed to finalize Stripe-confirmed dispute refund'));
      }
    } else {
      try {
        await this.resolutionExecution.finalizeSeller(dispute, {
          resolution: input.resolution,
          resolvedById: input.resolvedById ?? null,
        });
      } catch (error) {
        if (error instanceof Error && error.message === 'DISPUTE_NOT_RESOLVABLE') {
          return left(new BadRequestError('Dispute cannot be resolved while it is not open'));
        }
        return left(new DatabaseError('Failed to resolve dispute'));
      }
    }

    if (input.winner === DisputeWinner.SELLER) {
      await this.payoutService.payoutForOrder(dispute.orderId);
    }

    const buyerMsg = input.winner === DisputeWinner.BUYER ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do vendedor';
    const sellerMsg = input.winner === DisputeWinner.SELLER ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do comprador';
    await Promise.all([
      this.notificationService.notifyDispute(dispute.order.buyerId, dispute.id, dispute.orderId, buyerMsg),
      this.notificationService.notifyDispute(dispute.order.sellerId, dispute.id, dispute.orderId, sellerMsg),
    ]);

    return right(undefined);
  }
}
