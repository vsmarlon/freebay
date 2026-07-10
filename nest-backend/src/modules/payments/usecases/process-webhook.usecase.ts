import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProcessWebhookInput } from '../dtos/payment.dto';

@Injectable()
export class ProcessWebhookUseCase {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  async execute(input: ProcessWebhookInput): Promise<Either<AppError, { processed: boolean }>> {
    const { event, data } = input;

    if (event === 'charge.completed') {
      const webhookData = data as { correlationID?: string };
      const correlationID = webhookData.correlationID;
      if (!correlationID) {
        return right({ processed: false });
      }

      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: correlationID },
        include: { order: { include: { buyer: true, seller: true } } },
      });

      if (!transaction) {
        return right({ processed: false });
      }

      try {
        await this.prisma.$transaction(async (tx) => {
          const webhookProduct = await tx.product.findUnique({ where: { id: transaction.order.productId } });
          if (webhookProduct && webhookProduct.quantity > 1) {
            const newSoldCount = webhookProduct.soldCount + 1;
            await tx.product.update({
              where: { id: transaction.order.productId },
              data: {
                soldCount: newSoldCount,
                ...(newSoldCount >= webhookProduct.quantity ? { status: 'SOLD' as const } : {}),
              },
            });
          } else {
            await tx.product.update({
              where: { id: transaction.order.productId },
              data: { status: 'SOLD' },
            });
          }

          await tx.transaction.update({
            where: { id: transaction.id },
            data: { status: 'PAID', paidAt: new Date() },
          });

          await tx.order.update({
            where: { id: transaction.orderId },
            data: { status: 'CONFIRMED', escrowStatus: 'HELD' },
          });

          await tx.wallet.upsert({
            where: { userId: transaction.order.sellerId },
            create: {
              user: { connect: { id: transaction.order.sellerId } },
              pendingBalance: transaction.sellerAmount,
            },
            update: { pendingBalance: { increment: transaction.sellerAmount } },
          });
        });
      } catch {
        return left(new DatabaseError('Failed to process webhook'));
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

      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: correlationID },
        include: { order: true },
      });

      if (!transaction) {
        return right({ processed: false });
      }

      try {
        await this.prisma.$transaction(async (tx) => {
          await tx.transaction.update({
            where: { id: transaction.id },
            data: { status: 'FAILED' },
          });

          await tx.order.update({
            where: { id: transaction.orderId },
            data: { status: 'CANCELLED' },
          });

          const expiredProduct = await tx.product.findUnique({ where: { id: transaction.order.productId } });
          if (expiredProduct && expiredProduct.quantity > 1) {
            const newSoldCount = expiredProduct.soldCount - 1;
            await tx.product.update({
              where: { id: transaction.order.productId },
              data: {
                soldCount: newSoldCount >= 0 ? newSoldCount : 0,
                ...(expiredProduct.status === 'SOLD' && newSoldCount < expiredProduct.quantity ? { status: 'ACTIVE' as const } : {}),
              },
            });
          } else {
            await tx.product.updateMany({
              where: {
                id: transaction.order.productId,
                status: 'PAUSED',
              },
              data: { status: 'ACTIVE' },
            });
          }
        });
      } catch {
        return left(new DatabaseError('Failed to process webhook'));
      }

      return right({ processed: true });
    }

    return right({ processed: false });
  }
}
