import { Injectable } from '@nestjs/common';
import { DisputeStatus, EscrowStatus, OrderStatus, TransactionStatus, WalletEntryReason } from '@prisma/client';
import { Transactional, TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { DisputeWithOrder } from '../types/dispute.types';

@Injectable()
export class DisputeResolutionExecutionService {
  constructor(private readonly txHost: TransactionHost<TransactionalAdapterPrisma>) {}

  /**
   * Claims the dispute and finalizes a buyer refund inside one transaction.
   * The claim update moved here from the use case so that claim + money
   * moves stay atomic; throws DISPUTE_NOT_RESOLVABLE exactly as before.
   */
  @Transactional()
  async finalizeBuyer(
    dispute: DisputeWithOrder,
    refund: { operationId: string; providerId: string; amount: number },
    patch: { resolution: string; resolvedById: string | null },
  ): Promise<void> {
    const claimedDispute = await this.txHost.tx.dispute.updateMany({
      where: { id: dispute.id, status: { notIn: [DisputeStatus.RESOLVED, DisputeStatus.CANCELLED] } },
      data: {
        resolution: patch.resolution,
        resolvedById: patch.resolvedById,
        status: DisputeStatus.RESOLVED,
        resolvedAt: new Date(),
      },
    });
    if (claimedDispute.count === 0) throw new Error('DISPUTE_NOT_RESOLVABLE');

    const claimed = await this.txHost.tx.order.updateMany({
      where: {
        id: dispute.orderId,
        status: OrderStatus.DISPUTED,
        escrowStatus: EscrowStatus.HELD,
        cancellationReason: 'DISPUTE_REFUND_PENDING',
      },
      data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED },
    });
    if (claimed.count === 0) throw new Error('DISPUTE_ORDER_CLAIM_LOST');

    const transaction = await this.txHost.tx.transaction.updateMany({
      where: {
        orderId: dispute.orderId,
        refundOperationId: refund.operationId,
        refundProviderId: refund.providerId,
        refundAmount: refund.amount,
        status: { in: [TransactionStatus.PAID, TransactionStatus.HELD, TransactionStatus.RELEASED] },
      },
      data: { status: TransactionStatus.REFUNDED },
    });
    if (transaction.count !== 1) throw new Error('DISPUTE_REFUND_CLAIM_LOST');

    await applyWalletDelta(
      this.txHost.tx,
      dispute.order.sellerId,
      { pendingBalance: -dispute.order.sellerAmount },
      { reason: WalletEntryReason.HOLD_RELEASED, orderId: dispute.orderId },
    );
  }

  /**
   * Claims the dispute and completes a seller release inside one transaction.
   */
  @Transactional()
  async finalizeSeller(dispute: DisputeWithOrder, patch: { resolution: string; resolvedById: string | null }): Promise<void> {
    const claimedDispute = await this.txHost.tx.dispute.updateMany({
      where: { id: dispute.id, status: { notIn: [DisputeStatus.RESOLVED, DisputeStatus.CANCELLED] } },
      data: {
        resolution: patch.resolution,
        resolvedById: patch.resolvedById,
        status: DisputeStatus.RESOLVED,
        resolvedAt: new Date(),
      },
    });
    if (claimedDispute.count === 0) throw new Error('DISPUTE_NOT_RESOLVABLE');

    const claimed = await this.txHost.tx.order.updateMany({
      where: {
        id: dispute.orderId,
        status: OrderStatus.DISPUTED,
        escrowStatus: EscrowStatus.HELD,
        cancellationReason: null,
      },
      data: { status: OrderStatus.COMPLETED, escrowStatus: EscrowStatus.RELEASED },
    });
    if (claimed.count === 0) throw new Error('DISPUTE_ORDER_CLAIM_LOST');

    const transaction = await this.txHost.tx.transaction.updateMany({
      where: { orderId: dispute.orderId, status: TransactionStatus.PAID, refundOperationId: null },
      data: { status: TransactionStatus.RELEASED, releasedAt: new Date() },
    });
    if (transaction.count !== 1) throw new Error('DISPUTE_TRANSACTION_CLAIM_LOST');

    await applyWalletDelta(
      this.txHost.tx,
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
