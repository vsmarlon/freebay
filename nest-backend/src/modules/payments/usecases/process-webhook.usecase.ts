import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProcessWebhookInput } from '../dtos/payment.dto';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { WalletRepository } from '../../wallet/domain/repositories/wallet.repository';

// Thrown inside $transaction when the conditional PAID/FAILED transition matched
// zero rows — the concurrent Stripe delivery already mutated the transaction.
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

  async execute(input: ProcessWebhookInput): Promise<Either<DatabaseError, { processed: boolean }>> {
    const { event, data } = input;
    const orderId = data.orderId as string | undefined;

    if (!orderId) {
      return right({ processed: false });
    }

    if (event === 'checkout.session.completed' || event === 'payment_intent.succeeded') {
      return this._handleCompleted(orderId);
    }

    if (event === 'checkout.session.expired' || event === 'payment_intent.canceled') {
      return this._handleExpired(orderId);
    }

    if (event === 'payment_intent.payment_failed') {
      this.logger.warn(`Payment failed for order ${orderId}; leaving transaction as-is`);
      return right({ processed: false });
    }

    return right({ processed: false });
  }

  private async _handleCompleted(
    orderId: string,
  ): Promise<Either<DatabaseError, { processed: boolean }>> {
    const transactionResult = await this.transactionRepo.findByOrderId(orderId);
    if (isLeft(transactionResult)) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right({ processed: false });
    }

    if (transaction.status === 'PAID') {
      this.logger.log(`Transaction ${transaction.id} already PAID; skipping duplicate completion`);
      return right({ processed: true });
    }

    if (transaction.status !== 'PENDING') {
      this.logger.warn(
        `Transaction ${transaction.id} is ${transaction.status}; refusing to credit a non-PENDING transaction`,
      );
      return right({ processed: true });
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const paid = await this.transactionRepo.markAsPaid(transaction.id, tx);
        if (isLeft(paid)) throw new Error(paid.value.message);
        if (paid.value.count === 0) throw new Error(WEBHOOK_RACE_SKIP);
        await this.productRepo.updateInventoryOnSale(transaction.order.productId, tx);
        await this.orderRepo.confirm(transaction.orderId, tx);
        await this.walletRepo.creditPending(transaction.order.sellerId, transaction.sellerAmount, tx);
      });
    } catch (error) {
      if (error instanceof Error && error.message === WEBHOOK_RACE_SKIP) {
        this.logger.log(
          `Transaction ${transaction.id} lost the completion race; concurrent delivery already paid it`,
        );
        return right({ processed: true });
      }
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

    return right({ processed: true });
  }

  private async _handleExpired(
    orderId: string,
  ): Promise<Either<DatabaseError, { processed: boolean }>> {
    const transactionResult = await this.transactionRepo.findByOrderId(orderId);
    if (isLeft(transactionResult)) return left(transactionResult.value);

    const transaction = transactionResult.value;
    if (!transaction) {
      return right({ processed: false });
    }

    if (transaction.status !== 'PENDING') {
      this.logger.warn(
        `Transaction ${transaction.id} is ${transaction.status}; refusing to expire a non-PENDING transaction`,
      );
      return right({ processed: true });
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const failed = await this.transactionRepo.markAsFailed(transaction.id, tx);
        if (isLeft(failed)) throw new Error(failed.value.message);
        if (failed.value.count === 0) throw new Error(WEBHOOK_RACE_SKIP);
        await this.orderRepo.cancel(transaction.orderId, tx);
        await this.productRepo.restoreInventoryOnExpiry(transaction.order.productId, tx);
      });
    } catch (error) {
      if (error instanceof Error && error.message === WEBHOOK_RACE_SKIP) {
        this.logger.log(
          `Transaction ${transaction.id} lost the expiry race; skipping order cancellation`,
        );
        return right({ processed: true });
      }
      return left(new DatabaseError('Failed to process webhook'));
    }

    return right({ processed: true });
  }
}
