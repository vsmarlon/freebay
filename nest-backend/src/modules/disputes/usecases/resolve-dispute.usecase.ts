import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';

@Injectable()
export class ResolveDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  async execute(input: { disputeId: string; resolution: string; winner: 'BUYER' | 'SELLER' }): Promise<Either<AppError, { resolved: boolean }>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: input.disputeId },
      include: { order: true },
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.dispute.update({
        where: { id: input.disputeId },
        data: {
          resolution: input.resolution,
          status: 'RESOLVED',
          resolvedAt: new Date(),
        },
      });

      if (input.winner === 'BUYER') {
        await tx.order.update({
          where: { id: dispute.orderId },
          data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
        });

        const buyerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.buyerId } });
        if (buyerWallet) {
          await tx.wallet.update({
            where: { userId: dispute.order.buyerId },
            data: { availableBalance: { increment: dispute.order.amount } },
          });
        }
      } else {
        await tx.order.update({
          where: { id: dispute.orderId },
          data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
        });

        const sellerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.sellerId } });
        if (sellerWallet) {
          await tx.wallet.update({
            where: { userId: dispute.order.sellerId },
            data: {
              pendingBalance: { decrement: dispute.order.sellerAmount },
              availableBalance: { increment: dispute.order.sellerAmount },
              totalEarned: { increment: dispute.order.sellerAmount },
            },
          });
        }
      }
    });

    const buyerMsg = input.winner === 'BUYER' ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do vendedor';
    const sellerMsg = input.winner === 'SELLER' ? 'A disputa foi resolvida a seu favor' : 'A disputa foi resolvida a favor do comprador';
    await this.notificationService.notifyDispute(dispute.order.buyerId, dispute.id, buyerMsg);
    await this.notificationService.notifyDispute(dispute.order.sellerId, dispute.id, sellerMsg);

    return right({ resolved: true });
  }
}
