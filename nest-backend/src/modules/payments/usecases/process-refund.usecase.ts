import { Injectable, Logger } from '@nestjs/common';
import { EscrowStatus, OrderStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ConflictError, DatabaseError, PaymentProviderError } from '@/shared/core/errors';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { SellerPayoutService } from '../services/seller-payout.service';
import { StripeProvider } from '../providers/stripe-provider';
import { RefundSnapshot, RefundStatus } from '../types/payment-provider.types';

@Injectable()
export class ProcessRefundUseCase {
  private readonly logger = new Logger(ProcessRefundUseCase.name);

  constructor(
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly orderRepo: OrderDatabaseRepository,
    private readonly payoutService: SellerPayoutService,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(chargeId: string): Promise<Either<AppError, void>> {
    const canonical = await this.stripe.retrieveChargeRefunds(chargeId);
    if (canonical.isLeft()) return left(canonical.value);
    if (canonical.value.id !== chargeId) return left(new PaymentProviderError('Cobrança divergente na reconciliação'));

    for (const refund of canonical.value.refunds) {
      const result = await this.processCanonicalRefund(refund);
      if (result.isLeft()) return left(result.value);
    }
    return right(undefined);
  }

  async executeRefund(refundId: string): Promise<Either<AppError, void>> {
    const canonical = await this.stripe.retrieveRefund(refundId);
    if (canonical.isLeft()) return left(canonical.value);
    return this.processCanonicalRefund(canonical.value);
  }

  async recoverPendingRefunds(): Promise<Either<AppError, void>> {
    const recoveries = await this.transactionRepo.findPendingRefundRecoveries();
    if (recoveries.isLeft()) return left(recoveries.value);
    for (const recovery of recoveries.value) {
      const result = recovery.refundProviderId
        ? await this.executeRefund(recovery.refundProviderId)
        : await this.execute(recovery.chargeId);
      if (result.isLeft()) {
        this.logger.error(`Refund recovery remains held for order ${recovery.orderId}: ${result.value.message}`);
      }
    }
    return right(undefined);
  }

  private async processCanonicalRefund(refund: RefundSnapshot): Promise<Either<AppError, void>> {
    if (!refund.orderId || !refund.operationId) {
      this.logger.warn(`Ignoring unattributed Stripe refund ${refund.id}; manual reconciliation required`);
      return right(undefined);
    }

    const found = await this.transactionRepo.findByOrderId(refund.orderId);
    if (found.isLeft()) return left(found.value);
    const transaction = found.value;
    if (!transaction || transaction.refundOperationId !== refund.operationId ||
        transaction.refundAmount !== refund.amount || !transaction.chargeId ||
        transaction.chargeId !== refund.chargeId) {
      this.logger.warn(`Ignoring unbound Stripe refund ${refund.id}; order ${refund.orderId} remains held`);
      return right(undefined);
    }

    const recorded = await this.transactionRepo.recordRefundProviderId(refund.orderId, refund.operationId, refund.id);
    if (recorded.isLeft()) return left(recorded.value);
    if (!recorded.value) return left(new ConflictError('Refund operation identity changed'));

    if (refund.status === RefundStatus.PENDING || refund.status === RefundStatus.REQUIRES_ACTION ||
        refund.status === RefundStatus.FAILED || refund.status === RefundStatus.CANCELED) {
      if (refund.status === RefundStatus.FAILED || refund.status === RefundStatus.CANCELED) {
        this.logger.error(`Stripe refund ${refund.id} is ${refund.status}; order ${refund.orderId} remains held for manual review`);
      }
      return right(undefined);
    }
    if (refund.status !== RefundStatus.SUCCEEDED) {
      return left(new PaymentProviderError('Estado de reembolso exige reconciliação'));
    }

    const order = transaction.order;
    if (order.status === OrderStatus.CANCELLED && order.escrowStatus === EscrowStatus.REFUNDED) {
      return right(undefined);
    }
    const refundableStatuses: OrderStatus[] = [
      OrderStatus.CONFIRMED,
      OrderStatus.SHIPPED,
      OrderStatus.DELIVERED,
      OrderStatus.DISPUTED,
      OrderStatus.COMPLETED,
    ];
    if (!refundableStatuses.includes(order.status) ||
        (order.escrowStatus !== EscrowStatus.HELD && order.escrowStatus !== EscrowStatus.RELEASED)) {
      return left(new ConflictError('Pedido não está em estado seguro para finalizar o reembolso'));
    }

    const reversed = await this.payoutService.reverseForOrder(order.id);
    if (reversed.isLeft()) return left(reversed.value);

    const refunded = await this.orderRepo.refundOrder({
      orderId: order.id,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      escrowStatus: order.escrowStatus,
      orderQuantity: order.quantity,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
      transferId: transaction.transferId,
      refundOperationId: refund.operationId,
      refundProviderId: refund.id,
      refundAmount: refund.amount,
    });
    if (refunded.isLeft()) return left(new DatabaseError('Failed to finalize provider-confirmed refund'));
    if (!refunded.value) return left(new ConflictError('Refund finalization lost its order claim'));

    this.logger.log(`Finalized Stripe refund ${refund.id} for order ${order.id}`);
    return right(undefined);
  }
}
