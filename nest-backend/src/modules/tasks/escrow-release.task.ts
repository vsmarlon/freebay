import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { OrderStatus, EscrowStatus, TransactionStatus, WalletEntryReason } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import {
  DAYS_IN_MILLISECONDS,
  DISPUTE_OPENED_ERROR,
  ESCROW_RELEASE_DELAY_DAYS,
} from './task.constants';

@Injectable()
export class EscrowReleaseTask {
  private readonly logger = new Logger(EscrowReleaseTask.name);

  constructor(
    private prisma: PrismaService,
    private payoutService: SellerPayoutService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async autoReleaseDeliveredOrders() {
    const releaseCutoff = new Date(Date.now() - ESCROW_RELEASE_DELAY_DAYS * DAYS_IN_MILLISECONDS);

    const orders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED,
        deliveryConfirmedAt: { lt: releaseCutoff },
        dispute: null,
      },
      include: { dispute: true },
    });

    for (const order of orders) {
      if (order.dispute) continue;

      try {
        const released = await this.prisma.$transaction(async (tx) => {
          const claimed = await tx.order.updateMany({
            where: { id: order.id, status: OrderStatus.DELIVERED },
            data: { status: OrderStatus.COMPLETED, escrowStatus: EscrowStatus.RELEASED },
          });
          if (claimed.count === 0) {
            return false;
          }

          const dispute = await tx.dispute.findUnique({ where: { orderId: order.id } });
          if (dispute) {
            throw new Error(DISPUTE_OPENED_ERROR);
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
            data: { status: TransactionStatus.RELEASED, releasedAt: new Date() },
          });
          return true;
        });

        if (released) {
          await this.payoutService.payoutForOrder(order.id);
          this.logger.log(`Auto-released escrow for delivered order ${order.id}`);
        }
      } catch (error) {
        if (error instanceof Error && error.message === DISPUTE_OPENED_ERROR) {
          this.logger.warn(`Skipped auto-release for order ${order.id}: dispute opened`);
          continue;
        }
        this.logger.error(
          `Failed to auto-release escrow for order ${order.id}: ${error instanceof Error ? error.message : String(error)}`,
          error instanceof Error ? error.stack : undefined,
        );
      }
    }
  }
}
