import { Injectable } from '@nestjs/common';
import { OrderStatus, TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError, ConflictError, PaymentProviderError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { CancelOrderInput } from '../dtos/order.dto';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';

@Injectable()
export class CancelOrderUseCase {
  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly notificationService: NotificationService,
    private readonly transactions: TransactionDatabaseRepository,
    private readonly stripe: StripeProvider,
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
    if (order.status === OrderStatus.CONFIRMED) {
      if (!payment || (payment.status !== TransactionStatus.PAID && payment.status !== TransactionStatus.HELD) ||
          (!payment.chargeId && !payment.externalId?.startsWith('pi_'))) {
        return left(new PaymentProviderError('Pagamento sem referência reembolsável'));
      }
      const refund = await this.stripe.refundPayment({
        orderId: order.id, amount: order.amount,
        chargeId: payment.chargeId ?? undefined,
        paymentIntentId: payment.externalId?.startsWith('pi_') ? payment.externalId : undefined,
      });
      if (refund.isLeft()) return left(refund.value);
      if (refund.value === 'pending') {
        const recorded = await this.orderRepository.markRefundPending(order.id, input.reason);
        if (recorded.isLeft()) return left(recorded.value);
        return right('REFUND_PENDING');
      }
    } else if (payment?.status === TransactionStatus.PENDING) {
      if (payment.paymentGroupId) return left(new ConflictError('Cancele o checkout do carrinho inteiro'));
      if (payment.externalId) {
        const cancelled = await this.stripe.cancelPendingPayment({
          stripeSessionId: payment.externalId.startsWith('cs_') ? payment.externalId : undefined,
          stripePaymentIntentId: payment.externalId.startsWith('pi_') ? payment.externalId : undefined,
          idempotencyKey: `order-cancel-${order.id}`,
        });
        if (cancelled.isLeft()) return left(cancelled.value);
      }
    } else if (payment) {
      return left(new ConflictError('O pagamento não permite este cancelamento'));
    }

    const result = await this.orderRepository.cancelOrder({
      orderId: input.orderId,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      orderQuantity: order.quantity,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
      reason: input.reason,
    });
    if (result.isLeft()) return left(result.value);

    // Send notification to the other party
    const otherPartyId = order.buyerId === input.userId ? order.sellerId : order.buyerId;
    this.notificationService.create({
      userId: otherPartyId,
      type: 'ORDER',
      title: 'Pedido cancelado',
      body: `O pedido foi cancelado pelo outro usuário. Motivo: ${input.reason}`,
      extraData: { type: 'order', orderId: order.id },
    });

    return right('CANCELLED');
  }
}
