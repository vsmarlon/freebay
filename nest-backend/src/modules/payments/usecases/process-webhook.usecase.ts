import { Injectable, Logger } from '@nestjs/common';
import { OrderStatus, TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProcessWebhookInput, WebhookDataPayload } from '../dtos/payment.dto';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { WalletDatabaseRepository } from '../../wallet/data/repositories/wallet-database.repository';
import { TransactionWithOrder } from '../types/payment.types';

const WEBHOOK_RACE_SKIP = 'WEBHOOK_RACE_SKIP';
const WEBHOOK_ORDER_NOT_PENDING = 'WEBHOOK_ORDER_NOT_PENDING';

@Injectable()
export class ProcessWebhookUseCase {
  private readonly logger = new Logger(ProcessWebhookUseCase.name);

  constructor(
    private readonly productRepo: ProductDatabaseRepository,
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly orderRepo: PrismaOrderRepository,
    private readonly walletRepo: WalletDatabaseRepository,
    private readonly notificationService: NotificationService,
    private readonly prisma: PrismaService,
  ) {}

  async execute(input: ProcessWebhookInput): Promise<Either<DatabaseError, void>> {
    const { event, data } = input;
    const orderId = data.orderId as string | undefined;

    if (!orderId) {
      return right(undefined);
    }

    if (event === 'payment_intent.succeeded' || event === 'checkout.session.async_payment_succeeded') {
      return this._handleCompleted(orderId, data);
    }

    if (event === 'checkout.session.completed') {
      if (
        data.paymentStatus &&
        data.paymentStatus !== 'paid' &&
        data.paymentStatus !== 'no_payment_required'
      ) {
        this.logger.log(
          `checkout.session.completed for order ${orderId} is '${data.paymentStatus}'; awaiting async settlement`,
        );
        return right(undefined);
      }
      return this._handleCompleted(orderId, data);
    }

    if (
      event === 'checkout.session.expired' ||
      event === 'payment_intent.canceled' ||
      event === 'checkout.session.async_payment_failed'
    ) {
      return this._handleExpired(orderId, data);
    }

    if (event === 'payment_intent.payment_failed') {
      this.logger.warn(`Payment failed for order ${orderId}; leaving transaction as-is`);
      return right(undefined);
    }

    return right(undefined);
  }

  private async _handleCompleted(
    orderId: string,
    data: WebhookDataPayload,
  ): Promise<Either<DatabaseError, void>> {
    const transactionResult = await this.transactionRepo.findByOrderId(orderId);
    if (transactionResult.isLeft()) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right(undefined);
    }

    if (transaction.status === TransactionStatus.PAID) {
      if (data.chargeId && !transaction.chargeId) {
        await this.transactionRepo.setChargeId(transaction.orderId, data.chargeId);
      }
      this.logger.log(`Transaction ${transaction.id} already PAID; skipping duplicate completion`);
      return right(undefined);
    }

    if (transaction.status !== TransactionStatus.PENDING) {
      this.logger.warn(
        `Transaction ${transaction.id} is ${transaction.status}; refusing to credit a non-PENDING transaction`,
      );
      return right(undefined);
    }

    const mismatch = this._validateAgainstTransaction(transaction, data);
    if (mismatch) {
      this.logger.error(
        `Webhook object does not match transaction ${transaction.id} for order ${orderId}: ${mismatch}`,
      );
      return right(undefined);
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const paid = await this.transactionRepo.markAsPaid(transaction.id, data.chargeId ?? null, tx);
        if (paid.isLeft()) throw new Error(paid.value.message);
        if (paid.value.count === 0) throw new Error(WEBHOOK_RACE_SKIP);
        const confirmed = await this.orderRepo.confirm(transaction.orderId, tx);
        if (confirmed.isLeft()) throw new Error(confirmed.value.message);
        if (!confirmed.value) throw new Error(WEBHOOK_ORDER_NOT_PENDING);
        await this.productRepo.updateInventoryOnSale(transaction.order.productId, tx);
        await this.walletRepo.creditPending(
          transaction.order.sellerId,
          transaction.sellerAmount,
          transaction.orderId,
          tx,
        );
      });
    } catch (error) {
      if (error instanceof Error && error.message === WEBHOOK_RACE_SKIP) {
        this.logger.log(
          `Transaction ${transaction.id} lost the completion race; concurrent delivery already paid it`,
        );
        return right(undefined);
      }
      if (error instanceof Error && error.message === WEBHOOK_ORDER_NOT_PENDING) {
        this.logger.error(
          `Order ${orderId} is not PENDING; refusing to confirm and credit it from a payment webhook`,
        );
        return right(undefined);
      }
      this.logger.error(
        `Failed to settle transaction ${transaction.id} for order ${orderId}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      return left(new DatabaseError('Failed to process payment webhook'));
    }

    try {
      await this.notificationService.notifyPayment(transaction.order.sellerId, transaction.amount);
      await this.notificationService.notifyOrderStatus(transaction.order.buyerId, transaction.orderId, OrderStatus.CONFIRMED);
    } catch (error) {
      this.logger.error(
        `Payment notifications failed for order ${transaction.orderId}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }

    return right(undefined);
  }

  private async _handleExpired(
    orderId: string,
    data: WebhookDataPayload,
  ): Promise<Either<DatabaseError, void>> {
    const transactionResult = await this.transactionRepo.findByOrderId(orderId);
    if (transactionResult.isLeft()) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right(undefined);
    }

    if (transaction.status !== TransactionStatus.PENDING) {
      this.logger.warn(
        `Transaction ${transaction.id} is ${transaction.status}; refusing to expire a non-PENDING transaction`,
      );
      return right(undefined);
    }

    if (
      data.providerObjectId &&
      transaction.externalId &&
      data.providerObjectId !== transaction.externalId
    ) {
      this.logger.warn(
        `Expiry for order ${orderId} references ${data.providerObjectId} but the transaction holds ${transaction.externalId}; ignoring`,
      );
      return right(undefined);
    }

    if (transaction.order.status !== OrderStatus.PENDING) {
      this.logger.warn(
        `Order ${orderId} is ${transaction.order.status}; refusing to cancel it on expiry`,
      );
      return right(undefined);
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const failed = await this.transactionRepo.markAsFailed(transaction.id, tx);
        if (failed.isLeft()) throw new Error(failed.value.message);
        if (failed.value.count === 0) throw new Error(WEBHOOK_RACE_SKIP);
        await this.orderRepo.cancel(transaction.orderId, tx);
        await this.productRepo.restoreInventoryOnExpiry(transaction.order.productId, transaction.order.quantity, tx);
      });
    } catch (error) {
      if (error instanceof Error && error.message === WEBHOOK_RACE_SKIP) {
        this.logger.log(
          `Transaction ${transaction.id} lost the expiry race; skipping order cancellation`,
        );
        return right(undefined);
      }
      this.logger.error(
        `Failed to expire transaction ${transaction.id} for order ${orderId}: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      return left(new DatabaseError('Failed to process webhook'));
    }

    return right(undefined);
  }

  private _validateAgainstTransaction(
    transaction: TransactionWithOrder,
    data: WebhookDataPayload,
  ): string | null {
    if (
      data.providerObjectId &&
      transaction.externalId &&
      data.providerObjectId !== transaction.externalId
    ) {
      return `provider object ${data.providerObjectId} != externalId ${transaction.externalId}`;
    }
    if (data.amountTotal != null && data.amountTotal !== transaction.amount) {
      return `amount ${data.amountTotal} != expected ${transaction.amount}`;
    }
    if (data.currency && data.currency.toLowerCase() !== 'brl') {
      return `currency ${data.currency} != brl`;
    }
    return null;
  }
}
