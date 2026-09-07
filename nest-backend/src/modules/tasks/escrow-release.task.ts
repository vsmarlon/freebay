import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { WalletEntryReason } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';

@Injectable()
export class EscrowReleaseTask {
  private readonly logger = new Logger(EscrowReleaseTask.name);

  constructor(
    private prisma: PrismaService,
    private payoutService: SellerPayoutService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async autoReleaseDeliveredOrders() {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const orders = await this.prisma.order.findMany({
      where: {
        status: 'DELIVERED',
        deliveryConfirmedAt: { lt: sevenDaysAgo },
        dispute: null,
      },
      include: { dispute: true },
    });

    for (const order of orders) {
      if (order.dispute) continue;

      try {
        const released = await this.prisma.$transaction(async (tx) => {
          const claimed = await tx.order.updateMany({
            where: { id: order.id, status: 'DELIVERED' },
            data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
          });
          if (claimed.count === 0) {
            return false;
          }

          const dispute = await tx.dispute.findUnique({ where: { orderId: order.id } });
          if (dispute) {
            throw new Error('DISPUTE_OPENED');
          }

          await applyWalletDelta(
            tx,
            order.sellerId,
            {
              pendingBalance: -order.sellerAmount,
              availableBalance: order.sellerAmount,
              totalEarned: order.sellerAmount,
            },
            { reason: WalletEntryReason.SALE_RELEASED, orderId: order.id },
          );

          await tx.transaction.update({
            where: { orderId: order.id },
            data: { status: 'RELEASED', releasedAt: new Date() },
          });
          return true;
        });

        if (released) {
          await this.payoutService.payoutForOrder(order.id);
          this.logger.log(`Auto-released escrow for delivered order ${order.id}`);
        }
      } catch (e) {
        if ((e as Error).message === 'DISPUTE_OPENED') {
          this.logger.warn(`Skipped auto-release for order ${order.id}: dispute opened`);
          continue;
        }
        this.logger.error(`Failed to auto-release escrow for order ${order.id}`, e as Error);
      }
    }
  }
}
