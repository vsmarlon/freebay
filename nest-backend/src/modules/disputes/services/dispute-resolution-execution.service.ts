import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { DisputeWithOrder } from '../types/dispute.types';

@Injectable()
export class DisputeResolutionExecutionService {
  async resolveInFavorOfBuyer(tx: Prisma.TransactionClient, dispute: DisputeWithOrder): Promise<void> {
    const claimed = await tx.order.updateMany({
      where: { id: dispute.orderId, escrowStatus: 'HELD' },
      data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
    });
    if (claimed.count === 0) {
      return;
    }

    const buyerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.buyerId } });
    if (buyerWallet) {
      await tx.wallet.update({
        where: { userId: dispute.order.buyerId },
        data: { availableBalance: { increment: dispute.order.amount } },
      });
    }

    const sellerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.sellerId } });
    if (sellerWallet) {
      await tx.wallet.update({
        where: { userId: dispute.order.sellerId },
        data: { pendingBalance: { decrement: dispute.order.sellerAmount } },
      });
    }
  }

  async resolveInFavorOfSeller(tx: Prisma.TransactionClient, dispute: DisputeWithOrder): Promise<void> {
    const claimed = await tx.order.updateMany({
      where: { id: dispute.orderId, escrowStatus: 'HELD' },
      data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
    });
    if (claimed.count === 0) {
      return;
    }

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
}
