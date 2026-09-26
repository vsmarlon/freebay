import {
  EscrowStatus,
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
} from "../../types/order.types";
import { OrderReservationRepository } from "./order-reservation.repository";

export class OrderMutationRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reservations: OrderReservationRepository,
  ) {
  }

  async confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: data.orderId,
            escrowStatus: EscrowStatus.HELD,
            status: { in: [OrderStatus.CONFIRMED, OrderStatus.DELIVERED] },
          },
          data: {
            status: OrderStatus.COMPLETED,
            escrowStatus: EscrowStatus.RELEASED,
            deliveryConfirmedAt: new Date(),
          },
        });
        if (claimed.count === 0) return;
        await applyWalletDelta(tx, data.sellerId, {
          pendingBalance: -data.sellerAmount,
          availableBalance: data.sellerAmount,
          totalEarned: data.sellerAmount,
        }, { reason: WalletEntryReason.SALE_RELEASED, orderId: data.orderId });
        await tx.transaction.update({
          where: { orderId: data.orderId },
          data: { status: TransactionStatus.RELEASED, releasedAt: new Date() },
        });
      });
    }, "Erro ao confirmar entrega");
  }

  async cancelOrder(data: CancelOrderTxData): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: { id: data.orderId, status: data.status },
          data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED, cancellationReason: data.reason },
        });
        if (claimed.count === 0) return;
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
      });
    }, "Erro ao cancelar pedido");
  }

  async refundOrder(data: RefundOrderTxData): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: data.orderId,
            status: { in: [OrderStatus.CONFIRMED, OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.COMPLETED] },
            escrowStatus: { in: [EscrowStatus.HELD, EscrowStatus.RELEASED] },
          },
          data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED },
        });
        if (claimed.count === 0) return;
        await this.reservations.restoreProductInventory(tx, data.productId, data.orderQuantity);
        const sellerDelta = data.escrowStatus === EscrowStatus.RELEASED
          ? data.transferId ? null : { availableBalance: -data.sellerAmount, totalEarned: -data.sellerAmount }
          : { pendingBalance: -data.sellerAmount };
        if (sellerDelta) {
          await applyWalletDelta(tx, data.sellerId, sellerDelta, { reason: WalletEntryReason.REFUND, orderId: data.orderId });
        }
        await tx.transaction.updateMany({
          where: { orderId: data.orderId },
          data: { status: TransactionStatus.REFUNDED },
        });
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
