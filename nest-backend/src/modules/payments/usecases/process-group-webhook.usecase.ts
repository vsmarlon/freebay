import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { WalletDatabaseRepository } from '../../wallet/data/repositories/wallet-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { PaymentGroupDatabaseRepository } from '../data/repositories/payment-group-database.repository';
import { PaymentGroupSnapshot } from '../types/payment-group.types';
import { ProcessWebhookInput, WebhookDataPayload } from '../dtos/payment.dto';

const GROUP_RACE_SKIP = 'GROUP_RACE_SKIP';

const COMPLETION_EVENTS = [
  'payment_intent.succeeded',
  'checkout.session.completed',
  'checkout.session.async_payment_succeeded',
];

const EXPIRY_EVENTS = [
  'checkout.session.expired',
  'payment_intent.canceled',
  'checkout.session.async_payment_failed',
];

@Injectable()
export class ProcessGroupWebhookUseCase {
  private readonly logger = new Logger(ProcessGroupWebhookUseCase.name);

  constructor(
    private readonly paymentGroupRepo: PaymentGroupDatabaseRepository,
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly productRepo: ProductDatabaseRepository,
    private readonly orderRepo: PrismaOrderRepository,
    private readonly walletRepo: WalletDatabaseRepository,
    private readonly notificationService: NotificationService,
    private readonly prisma: PrismaService,
  ) {}

  async execute(input: ProcessWebhookInput): Promise<Either<DatabaseError, void>> {
    const { event, data } = input;
    const groupId = data.paymentGroupId as string | undefined;
    if (!groupId) return right(undefined);

    const isCompletion = COMPLETION_EVENTS.includes(event);
    const isExpiry = EXPIRY_EVENTS.includes(event);
    if (!isCompletion && !isExpiry) {
      this.logger.warn(`Ignoring event ${event} for payment group ${groupId}`);
      return right(undefined);
    }

    if (
      event === 'checkout.session.completed' &&
      data.paymentStatus &&
      data.paymentStatus !== 'paid' &&
      data.paymentStatus !== 'no_payment_required'
    ) {
      this.logger.log(
        `checkout.session.completed for group ${groupId} is '${data.paymentStatus}'; awaiting async settlement`,
      );
      return right(undefined);
    }

    const groupResult = await this.paymentGroupRepo.findById(groupId);
    if (isLeft(groupResult)) return left(new DatabaseError('Failed to load payment group'));

    const group = groupResult.value;
    if (!group) {
      this.logger.warn(`Payment group ${groupId} not found`);
      return right(undefined);
    }

    if (group.status !== 'PENDING') {
      this.logger.log(`Payment group ${groupId} is already ${group.status}; skipping ${event}`);
      return right(undefined);
    }

    return isCompletion ? this.complete(group, data) : this.expire(group);
  }

  private async complete(
    group: PaymentGroupSnapshot,
    data: WebhookDataPayload,
  ): Promise<Either<DatabaseError, void>> {
    const mismatch = this.validate(group, data);
    if (mismatch) {
      this.logger.error(`Webhook object does not match payment group ${group.id}: ${mismatch}`);
      return right(undefined);
    }

    const chargeId = (data.chargeId as string | undefined) ?? null;

    try {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await this.paymentGroupRepo.claimPaid(group.id, chargeId, tx);
        if (claimed === 0) throw new Error(GROUP_RACE_SKIP);

        for (const order of group.orders) {
          const paid = await this.transactionRepo.markAsPaid(order.transactionId, chargeId, tx);
          if (isLeft(paid)) throw new Error(paid.value.message);
          if (paid.value.count === 0) continue;

          await this.productRepo.updateInventoryOnSale(order.productId, tx);
          await this.orderRepo.confirm(order.orderId, tx);
          await this.walletRepo.creditPending(order.sellerId, order.sellerAmount, order.orderId, tx);
        }
      });
    } catch (error) {
      if (error instanceof Error && error.message === GROUP_RACE_SKIP) {
        this.logger.log(
          `Payment group ${group.id} lost the completion race; a concurrent delivery already paid it`,
        );
        return right(undefined);
      }
      this.logger.error(
        `Failed to settle payment group ${group.id}: ${(error as Error).message}`,
        error instanceof Error ? error.stack : undefined,
      );
      return left(new DatabaseError('Failed to process payment webhook'));
    }

    for (const order of group.orders) {
      try {
        await this.notificationService.notifyPayment(order.sellerId, order.amount);
        await this.notificationService.notifyOrderStatus(order.buyerId, order.orderId, 'CONFIRMED');
      } catch (error) {
        this.logger.error(
          `Payment notifications failed for order ${order.orderId}: ${(error as Error).message}`,
        );
      }
    }

    return right(undefined);
  }

  private async expire(
    group: PaymentGroupSnapshot,
  ): Promise<Either<DatabaseError, void>> {
    try {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await this.paymentGroupRepo.markTerminal(group.id, 'EXPIRED', tx);
        if (claimed === 0) throw new Error(GROUP_RACE_SKIP);

        for (const order of group.orders) {
          const failed = await this.transactionRepo.markAsFailed(order.transactionId, tx);
          if (isLeft(failed)) throw new Error(failed.value.message);
          if (failed.value.count === 0) continue;

          await this.orderRepo.cancel(order.orderId, tx);
          await this.productRepo.restoreInventoryOnExpiry(order.productId, order.quantity, tx);
        }
      });
    } catch (error) {
      if (error instanceof Error && error.message === GROUP_RACE_SKIP) {
        this.logger.log(`Payment group ${group.id} lost the expiry race; skipping`);
        return right(undefined);
      }
      this.logger.error(
        `Failed to expire payment group ${group.id}: ${(error as Error).message}`,
        error instanceof Error ? error.stack : undefined,
      );
      return left(new DatabaseError('Failed to process webhook'));
    }

    return right(undefined);
  }

  private validate(group: PaymentGroupSnapshot, data: WebhookDataPayload): string | null {
    const providerObjectId = data.providerObjectId as string | undefined;
    const expectedObjectId = group.stripePaymentIntentId ?? group.stripeSessionId;
    if (providerObjectId && expectedObjectId && providerObjectId !== expectedObjectId) {
      return `provider object ${providerObjectId} != group object ${expectedObjectId}`;
    }

    const expectedTotal = group.orders.reduce((sum, order) => sum + order.amount, 0);
    if (data.amountTotal != null && data.amountTotal !== expectedTotal) {
      return `amount ${data.amountTotal} != sum of orders ${expectedTotal}`;
    }

    if (data.currency && data.currency.toLowerCase() !== 'brl') {
      return `currency ${data.currency} != brl`;
    }

    return null;
  }
}
