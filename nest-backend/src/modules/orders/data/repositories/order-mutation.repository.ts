import {
  EscrowStatus,
  DisputeStatus,
  OrderStatus,
  Prisma,
  TransactionStatus,
  WalletEntryReason,
} from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { RepositoryResponse } from "@/shared/core/either";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { applyWalletDelta } from "@/shared/wallet/wallet-mutation";
import {
  CancelOrderTxData,
  ConfirmDeliveryData,
  RefundOrderTxData,
  CancellationClaimOwner,
} from "../../types/order.types";
import { OrderReservationRepository } from "./order-reservation.repository";

export class OrderMutationRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reservations: OrderReservationRepository,
  ) {
  }

  async confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      return this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: data.orderId,
            escrowStatus: EscrowStatus.HELD,
            status: { in: [OrderStatus.CONFIRMED, OrderStatus.SHIPPED, OrderStatus.DELIVERED] },
            cancellationReason: null,
            transaction: { is: { status: { in: [TransactionStatus.PAID, TransactionStatus.HELD] }, refundOperationId: null } },
          },
          data: {
            status: OrderStatus.COMPLETED,
            escrowStatus: EscrowStatus.RELEASED,
            deliveryConfirmedAt: new Date(),
          },
        });
        if (claimed.count === 0) return false;
        await applyWalletDelta(tx, data.sellerId, {
          pendingBalance: -data.sellerAmount,
          availableBalance: data.sellerAmount,
          totalEarned: data.sellerAmount,
        }, { reason: WalletEntryReason.SALE_RELEASED, orderId: data.orderId });
        await tx.transaction.update({
          where: { orderId: data.orderId, status: { in: [TransactionStatus.PAID, TransactionStatus.HELD] } },
          data: { status: TransactionStatus.RELEASED, releasedAt: new Date() },
        });
        return true;
      });
    }, "Erro ao confirmar entrega");
  }

  markDelivered(orderId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const result = await this.prisma.order.updateMany({
        where: {
          id: orderId,
          status: OrderStatus.SHIPPED,
          cancellationReason: null,
          transaction: { is: { status: { in: [TransactionStatus.PAID, TransactionStatus.HELD] }, refundOperationId: null } },
        },
        data: { status: OrderStatus.DELIVERED, deliveryConfirmedAt: new Date() },
      });
      return result.count > 0;
    }, 'Erro ao marcar pedido como entregue');
  }

  async cancelOrder(data: CancelOrderTxData): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      return this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: { id: data.orderId, status: data.status, cancellationReason: data.reason },
          data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED, cancellationReason: data.reason },
        });
        if (claimed.count === 0) return false;
        await this.reservations.restoreProductInventory(tx, data.productId, data.orderQuantity);
        if (data.status === OrderStatus.CONFIRMED) {
          await applyWalletDelta(tx, data.sellerId, { pendingBalance: -data.sellerAmount }, { reason: WalletEntryReason.HOLD_RELEASED, orderId: data.orderId });
          await tx.transaction.updateMany({
            where: { orderId: data.orderId },
            data: { status: TransactionStatus.REFUNDED },
          });
        } else {
          await tx.transaction.updateMany({
            where: { orderId: data.orderId, status: TransactionStatus.PENDING },
            data: { status: TransactionStatus.FAILED },
          });
        }
        return true;
      });
    }, "Erro ao cancelar pedido");
  }

  claimCancellation(
    orderId: string,
    status: OrderStatus,
    reason: string,
    owner?: CancellationClaimOwner,
  ): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const claimed = await this.prisma.order.updateMany({
        where: {
          id: orderId,
          status,
          ...(owner ? { cancellationReason: null } : { OR: [{ cancellationReason: null }, { cancellationReason: reason }] }),
        },
        data: { cancellationReason: reason },
      });
      if (claimed.count > 0 || !owner) return claimed.count > 0;
      const transactionOwner = 'refundOperationId' in owner
        ? { refundOperationId: owner.refundOperationId }
        : { idempotencyKey: owner.paymentIdempotencyKey };
      const alreadyOwned = await this.prisma.order.findFirst({
        where: {
          id: orderId,
          status,
          cancellationReason: { not: null },
          transaction: { is: transactionOwner },
        },
        select: { id: true },
      });
      return alreadyOwned !== null;
    }, 'Erro ao reivindicar cancelamento');
  }

  async refundOrder(data: RefundOrderTxData): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      return this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: data.orderId,
            status: data.status,
            escrowStatus: { in: [EscrowStatus.HELD, EscrowStatus.RELEASED] },
            cancellationReason: { not: null },
            transaction: { is: {
              refundOperationId: data.refundOperationId,
              refundProviderId: data.refundProviderId,
              refundAmount: data.refundAmount,
              status: { in: [TransactionStatus.PAID, TransactionStatus.HELD, TransactionStatus.RELEASED] },
            } },
          },
          data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED },
        });
        if (claimed.count === 0) return false;
        await this.reservations.restoreProductInventory(tx, data.productId, data.orderQuantity);
        const sellerDelta = data.escrowStatus === EscrowStatus.RELEASED
          ? data.transferId ? null : { availableBalance: -data.sellerAmount, totalEarned: -data.sellerAmount }
          : { pendingBalance: -data.sellerAmount };
        if (sellerDelta) {
          await applyWalletDelta(tx, data.sellerId, sellerDelta, { reason: WalletEntryReason.REFUND, orderId: data.orderId });
        }
        const transaction = await tx.transaction.updateMany({
          where: {
            orderId: data.orderId,
            refundOperationId: data.refundOperationId,
            refundProviderId: data.refundProviderId,
            refundAmount: data.refundAmount,
            status: { in: [TransactionStatus.PAID, TransactionStatus.HELD, TransactionStatus.RELEASED] },
          },
          data: { status: TransactionStatus.REFUNDED },
        });
        if (transaction.count !== 1) throw new Error('Refund transaction claim was lost');
        await tx.dispute.updateMany({
          where: { orderId: data.orderId, status: { notIn: [DisputeStatus.RESOLVED, DisputeStatus.CANCELLED] } },
          data: {
            status: DisputeStatus.RESOLVED,
            resolution: data.disputeResolution ?? 'Stripe refund succeeded',
            resolvedById: data.resolvedById ?? null,
            resolvedAt: new Date(),
          },
        });
        return true;
      });
    }, "Erro ao reembolsar pedido");
  }

  async confirm(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const client = tx ?? this.prisma;
      const claimed = await client.order.updateMany({
        where: { id: orderId, status: OrderStatus.PENDING },
        data: { status: OrderStatus.CONFIRMED, escrowStatus: EscrowStatus.HELD },
      });
      return claimed.count > 0;
    }, "Failed to confirm order");
  }

  markRefundPending(orderId: string, reason: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.order.updateMany({
        where: { id: orderId, status: OrderStatus.CONFIRMED },
        data: { cancellationReason: reason },
      });
    }, 'Erro ao registrar reembolso pendente');
  }

  markShipped(orderId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const result = await this.prisma.order.updateMany({
        where: { id: orderId, status: OrderStatus.CONFIRMED, cancellationReason: null },
        data: { status: OrderStatus.SHIPPED },
      });
      return result.count > 0;
    }, 'Erro ao enviar pedido');
  }

  async cancel(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const client = tx ?? this.prisma;
      const claimed = await client.order.updateMany({
        where: { id: orderId, status: { notIn: [OrderStatus.CANCELLED, OrderStatus.COMPLETED, OrderStatus.DELIVERED, OrderStatus.SHIPPED] } },
        data: { status: OrderStatus.CANCELLED },
      });
      return claimed.count > 0;
    }, "Failed to cancel order");
  }
}
