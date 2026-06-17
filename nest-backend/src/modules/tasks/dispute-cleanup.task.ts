import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class DisputeCleanupTask {
  private readonly logger = new Logger(DisputeCleanupTask.name);

  constructor(private prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async cleanupExpiredDisputes() {
    const expiredDisputes = await this.prisma.dispute.findMany({
      where: {
        status: { in: ['OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER'] },
        expiresAt: { lt: new Date() },
      },
      include: { order: true },
    });

    for (const dispute of expiredDisputes) {
      await this.prisma.$transaction(async (tx) => {
        await tx.dispute.update({
          where: { id: dispute.id },
          data: {
            status: 'RESOLVED',
            resolution: 'Auto-resolved: dispute window expired',
            resolvedAt: new Date(),
          },
        });

        await tx.order.update({
          where: { id: dispute.orderId },
          data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
        });

        const wallet = await tx.wallet.findUnique({
          where: { userId: dispute.order.sellerId },
        });

        if (wallet) {
          await tx.wallet.update({
            where: { userId: dispute.order.sellerId },
            data: {
              pendingBalance: { decrement: dispute.order.sellerAmount },
              availableBalance: { increment: dispute.order.sellerAmount },
              totalEarned: { increment: dispute.order.sellerAmount },
            },
          });
        }
      });

      this.logger.log(`Auto-resolved expired dispute ${dispute.id} in favor of seller`);
    }
  }
}
