import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProcessWebhookInput } from '../dtos/payment.dto';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { WalletRepository } from '../../wallet/domain/repositories/wallet.repository';

@Injectable()
export class ProcessWebhookUseCase {
  constructor(
    private productRepo: ProductRepository,
    private transactionRepo: TransactionRepository,
    private orderRepo: OrderRepository,
    private walletRepo: WalletRepository,
    private notificationService: NotificationService,
    private prisma: PrismaService,
  ) {}

  async execute(input: ProcessWebhookInput): Promise<Either<DatabaseError, { processed: boolean }>> {
    const { event, data } = input;

    if (event === 'charge.completed') {
      const webhookData = data as { correlationID?: string };
      const correlationID = webhookData.correlationID;
      if (!correlationID) {
        return right({ processed: false });
      }

      const transactionResult = await this.transactionRepo.findByIdempotencyKey(correlationID);
      if (transactionResult.isLeft()) return left(transactionResult.value);

      const transaction = transactionResult.value;
      if (!transaction) {
        return right({ processed: false });
      }

      try {
        await this.prisma.$transaction(async (tx) => {
          await this.productRepo.updateInventoryOnSale(transaction.order.productId, tx);
          await this.transactionRepo.markAsPaid(transaction.id, tx);
          await this.orderRepo.confirm(transaction.orderId, tx);
          await this.walletRepo.creditPending(transaction.order.sellerId, transaction.sellerAmount, tx);
        });
      } catch {
        return left(new DatabaseError('Failed to process payment webhook'));
      }

      await this.notificationService.notifyPayment(transaction.order.sellerId, transaction.amount);
      await this.notificationService.notifyOrderStatus(transaction.order.buyerId, transaction.orderId, 'CONFIRMED');

      return right({ processed: true });
    }

    if (event === 'charge.expired') {
      const webhookData = data as { correlationID?: string };
      const correlationID = webhookData.correlationID;
      if (!correlationID) {
        return right({ processed: false });
      }

      const transactionResult = await this.transactionRepo.findByIdempotencyKey(correlationID);
      if (transactionResult.isLeft()) return left(transactionResult.value);

      const transaction = transactionResult.value;
      if (!transaction) {
        return right({ processed: false });
      }

      try {
        await this.prisma.$transaction(async (tx) => {
          await this.transactionRepo.markAsFailed(transaction.id, tx);
          await this.orderRepo.cancel(transaction.orderId, tx);
          await this.productRepo.restoreInventoryOnExpiry(transaction.order.productId, tx);
        });
      } catch {
        return left(new DatabaseError('Failed to process webhook'));
      }

      return right({ processed: true });
    }

    return right({ processed: false });
  }
}
