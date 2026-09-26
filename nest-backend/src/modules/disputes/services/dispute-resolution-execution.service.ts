import { Injectable } from '@nestjs/common';
import { EscrowStatus, OrderStatus, Prisma, WalletEntryReason } from '@prisma/client';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { DisputeWithOrder } from '../types/dispute.types';

@Injectable()
export class DisputeResolutionExecutionService {
  async resolveInFavorOfBuyer(tx: Prisma.TransactionClient, dispute: DisputeWithOrder): Promise<void> {
    const claimed = await tx.order.updateMany({
      where: { id: dispute.orderId, escrowStatus: EscrowStatus.HELD },
      data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED },
    });
    if (claimed.count === 0) {
      return;
    }

    await applyWalletDelta(
      tx,
      dispute.order.buyerId,
      { availableBalance: dispute.order.amount },
      { reason: WalletEntryReason.DISPUTE_REFUND, orderId: dispute.orderId },
    );
    await applyWalletDelta(
      tx,
      dispute.order.sellerId,
      { pendingBalance: -dispute.order.sellerAmount },
      { reason: WalletEntryReason.HOLD_RELEASED, orderId: dispute.orderId },
    );
  }

  async resolveInFavorOfSeller(tx: Prisma.TransactionClient, dispute: DisputeWithOrder): Promise<void> {
    const claimed = await tx.order.updateMany({
      where: { id: dispute.orderId, escrowStatus: EscrowStatus.HELD },
      data: { status: OrderStatus.COMPLETED, escrowStatus: EscrowStatus.RELEASED },
    });
    if (claimed.count === 0) {
      return;
    }

    await applyWalletDelta(
      tx,
      dispute.order.sellerId,
      {
        pendingBalance: -dispute.order.sellerAmount,
        availableBalance: dispute.order.sellerAmount,
        totalEarned: dispute.order.sellerAmount,
      },
      { reason: WalletEntryReason.DISPUTE_RELEASE, orderId: dispute.orderId },
    );
  }
}
