import { Injectable } from '@nestjs/common';
import { OrderStatus, TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError, ConflictError, PaymentProviderError, BadRequestError } from '@/shared/core/errors';
import { EscrowStatus } from '@prisma/client';
import { OrderDatabaseRepository } from '../data/repositories/order-database.repository';
import { CancelOrderInput } from '../dtos/order.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';

@Injectable()
export class CancelOrderUseCase {
  constructor(
    private readonly orderRepository: OrderDatabaseRepository,
    private readonly notificationService: NotificationService,
    private readonly transactions: TransactionDatabaseRepository,
    private readonly stripe: StripeProvider,
    private readonly payoutService: SellerPayoutService,
  ) {}

  async execute(input: CancelOrderInput): Promise<Either<AppError, 'CANCELLED' | 'REFUND_PENDING'>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (orderResult.isLeft()) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId && order.sellerId !== input.userId) {
      return left(new UnauthorizedError('Not authorized to cancel this order'));
    }
    if (order.status !== OrderStatus.PENDING && order.status !== OrderStatus.CONFIRMED) {
      return left(new InvalidOrderStateError('PENDING or CONFIRMED', order.status));
    }

    const found = await this.transactions.findByOrderId(order.id);
    if (found.isLeft()) return left(found.value);
    const payment = found.value;
    if (order.status === OrderStatus.PENDING && payment?.status === TransactionStatus.PENDING && payment.paymentGroupId) {
      return left(new ConflictError('Cancele o checkout do carrinho inteiro'));
    }
    if (order.status === OrderStatus.CONFIRMED && (!payment ||
        (payment.status !== TransactionStatus.PAID && payment.status !== TransactionStatus.HELD) ||
        (!payment.chargeId && !payment.externalId?.startsWith('pi_')))) {
      return left(new PaymentProviderError('Pagamento sem referência reembolsável'));
    }
    if (order.status === OrderStatus.PENDING && payment && payment.status !== TransactionStatus.PENDING) {
      return left(new ConflictError('O pagamento não permite este cancelamento'));
    }

    const reason = input.reason.replace(/\p{Cc}/gu, '').slice(0, 500);
    if (!reason.trim()) return left(new BadRequestError('Informe um motivo de cancelamento válido'));

    if (order.status === OrderStatus.PENDING && payment?.status === TransactionStatus.PENDING && !payment.externalId) {
      return left(new PaymentProviderError('Pagamento sem identidade Stripe permanece retido para reconciliação'));
    }

    let refundReservation: {
      operationId: string;
      idempotencyKey: string;
      providerId: string | null;
      created: boolean;
    } | undefined;
    if (order.status === OrderStatus.CONFIRMED) {
      if (!payment) return left(new PaymentProviderError('Pagamento sem referência reembolsável'));
      if (!payment.chargeId) return left(new PaymentProviderError('Cobrança pendente de reconciliação'));
      const providerState = await this.stripe.retrieveChargeRefunds(payment.chargeId);
      if (providerState.isLeft()) return left(providerState.value);
      const reservation = await this.transactions.reserveRefund(order.id, order.amount, providerState.value);
      if (reservation.isLeft()) return left(reservation.value);
      refundReservation = reservation.value;
    }

    const owner = refundReservation
      ? { refundOperationId: refundReservation.operationId }
      : payment?.status === TransactionStatus.PENDING
        ? { paymentIdempotencyKey: payment.idempotencyKey }
        : undefined;
    const claimed = await this.orderRepository.claimCancellation(order.id, order.status, reason, owner);
    if (claimed.isLeft()) return left(claimed.value);
    if (!claimed.value) return left(new ConflictError('O pedido não pode mais ser cancelado'));

    if (payment?.transferId) {
      const reversed = await this.payoutService.reverseForOrder(order.id);
      if (reversed.isLeft()) return left(reversed.value);
    }

    let refundIdentity: { operationId: string; providerId: string; amount: number } | undefined;
    if (order.status === OrderStatus.CONFIRMED) {
      if (!payment) return left(new PaymentProviderError('Pagamento sem referência reembolsável'));
      if (!refundReservation) return left(new PaymentProviderError('Operação de reembolso pendente de reconciliação'));
      const refund = await this.stripe.refundPayment({
        orderId: order.id, amount: order.amount,
        chargeId: payment.chargeId ?? undefined,
        paymentIntentId: payment.externalId?.startsWith('pi_') ? payment.externalId : undefined,
        operationId: refundReservation.operationId,
        idempotencyKey: refundReservation.idempotencyKey,
        knownProviderId: refundReservation.providerId,
        allowCreate: refundReservation.created,
      });
      if (refund.isLeft()) return left(refund.value);
      const recorded = await this.transactions.recordRefundProviderId(order.id, refundReservation.operationId, refund.value.id);
      if (recorded.isLeft()) return left(recorded.value);
      if (!recorded.value) return left(new ConflictError('Reembolso exige reconciliação manual'));
      refundIdentity = {
        operationId: refundReservation.operationId,
        providerId: refund.value.id,
        amount: refund.value.amount,
      };
      if (refund.value.status !== 'succeeded') {
        if (refund.value.status === 'failed' || refund.value.status === 'canceled') {
          return left(new PaymentProviderError('Reembolso não concluído; pedido permanece retido para revisão'));
        }
        return right('REFUND_PENDING');
      }
    } else if (payment?.status === TransactionStatus.PENDING) {
      if (payment.externalId) {
        const cancelled = await this.stripe.cancelPendingPayment({
          stripeSessionId: payment.externalId.startsWith('cs_') ? payment.externalId : undefined,
          stripePaymentIntentId: payment.externalId.startsWith('pi_') ? payment.externalId : undefined,
          idempotencyKey: `order-cancel-${order.id}`,
        });
        if (cancelled.isLeft()) return left(cancelled.value);
      }
    }

    const cancelData = {
      orderId: input.orderId,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      orderQuantity: order.quantity,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
      reason,
    };
    const result = order.status === OrderStatus.CONFIRMED && refundIdentity
      ? await this.orderRepository.refundOrder({
          ...cancelData,
          status: order.status,
          escrowStatus: order.escrowStatus === EscrowStatus.RELEASED ? EscrowStatus.RELEASED : EscrowStatus.HELD,
          transferId: payment?.transferId ?? null,
          refundOperationId: refundIdentity.operationId,
          refundProviderId: refundIdentity.providerId,
          refundAmount: refundIdentity.amount,
        })
      : await this.orderRepository.cancelOrder(cancelData);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new ConflictError('O pedido não pode mais ser cancelado'));

    // Send notification to the other party
    const otherPartyId = order.buyerId === input.userId ? order.sellerId : order.buyerId;
    this.notificationService.create({
      userId: otherPartyId,
      type: 'ORDER',
      title: 'Pedido cancelado',
      body: `O pedido foi cancelado pelo outro usuário. Motivo: ${reason}`,
      extraData: { type: 'order', orderId: order.id },
    });

    return right('CANCELLED');
  }
}
