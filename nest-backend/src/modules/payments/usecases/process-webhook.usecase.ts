import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProcessWebhookInput, WebhookDataPayload } from '../dtos/payment.dto';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { WalletRepository } from '../../wallet/domain/repositories/wallet.repository';
import { TransactionWithOrder } from '../types/payment.types';

const WEBHOOK_RACE_SKIP = 'WEBHOOK_RACE_SKIP';

@Injectable()
export class ProcessWebhookUseCase {
  private readonly logger = new Logger(ProcessWebhookUseCase.name);

  constructor(
    private readonly productRepo: ProductRepository,
    private readonly transactionRepo: TransactionRepository,
    private readonly orderRepo: OrderRepository,
    private readonly walletRepo: WalletRepository,
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
      return this._handleExpired(orderId);
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
    if (isLeft(transactionResult)) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right(undefined);
    }

    if (transaction.status === 'PAID') {
      if (data.chargeId && !transaction.chargeId) {
        await this.transactionRepo.setChargeId(transaction.orderId, data.chargeId);
      }
      this.logger.log(`Transaction ${transaction.id} already PAID; skipping duplicate completion`);
      return right(undefined);
    }

    if (transaction.status !== 'PENDING') {
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
        if (isLeft(paid)) throw new Error(paid.value.message);
        if (paid.value.count === 0) throw new Error(WEBHOOK_RACE_SKIP);
        await this.productRepo.updateInventoryOnSale(transaction.order.productId, tx);
        await this.orderRepo.confirm(transaction.orderId, tx);
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
      this.logger.error(
        `Failed to settle transaction ${transaction.id} for order ${orderId}: ${(error as Error).message}`,
        error instanceof Error ? error.stack : undefined,
      );
      return left(new DatabaseError('Failed to process payment webhook'));
    }

    try {
      await this.notificationService.notifyPayment(transaction.order.sellerId, transaction.amount);
      await this.notificationService.notifyOrderStatus(transaction.order.buyerId, transaction.orderId, 'CONFIRMED');
    } catch (error) {
      this.logger.error(
        `Payment notifications failed for order ${transaction.orderId}: ${(error as Error).message}`,
      );
    }

    return right(undefined);
  }

  private async _handleExpired(
    orderId: string,
  ): Promise<Either<DatabaseError, void>> {
    const transactionResult = await this.transactionRepo.findByOrderId(orderId);
    if (isLeft(transactionResult)) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right(undefined);
    }

    if (transaction.status !== 'PENDING') {
      this.logger.warn(
        `Transaction ${transaction.id} is ${transaction.status}; refusing to expire a non-PENDING transaction`,
      );
      return right(undefined);
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const failed = await this.transactionRepo.markAsFailed(transaction.id, tx);
        if (isLeft(failed)) throw new Error(failed.value.message);
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
        `Failed to expire transaction ${transaction.id} for order ${orderId}: ${(error as Error).message}`,
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
