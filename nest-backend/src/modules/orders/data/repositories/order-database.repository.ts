import { Injectable } from '@nestjs/common';
import { WalletEntryReason } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { DatabaseError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { OrderRepository } from '../../domain/repositories/order.repository';
import {
  OrderFullPayload,
  OrderProductPayload,
  CreateOrderTxData,
  ConfirmDeliveryData,
  CancelOrderTxData,
  ProductForOrder,
  ORDER_INCLUDE_FULL,
  ORDER_INCLUDE_PRODUCT,
} from '../../types/order.types';
import { Product, Prisma } from '@prisma/client';

@Injectable()
export class PrismaOrderRepository implements OrderRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): RepositoryResponse<OrderFullPayload | null> {
    try {
      const order = await this.prisma.order.findUnique({
        where: { id },
        include: ORDER_INCLUDE_FULL,
      });
      return right(order as OrderFullPayload | null);
    } catch {
      return left(new DatabaseError('Erro ao buscar pedido'));
    }
  }

  async findProductForOrder(productId: string): RepositoryResponse<ProductForOrder | null> {
    try {
      const product = await this.prisma.product.findUnique({
        where: { id: productId },
        select: { id: true, sellerId: true, price: true },
      });
      return right(product);
    } catch {
      return left(new DatabaseError('Erro ao buscar produto'));
    }
  }

  async findByBuyerId(
    buyerId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.findOrderPage({ buyerId }, page);
  }

  async findBySellerId(
    sellerId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.findOrderPage({ sellerId }, page);
  }

  private async findOrderPage(
    where: Prisma.OrderWhereInput,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    try {
      const result = await paginateById<OrderProductPayload, Prisma.OrderFindManyArgs>(
        (args) => this.prisma.order.findMany(args) as Promise<OrderProductPayload[]>,
        {
          where,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          include: ORDER_INCLUDE_PRODUCT,
        },
        page,
      );
      return right(result);
    } catch {
      return left(new DatabaseError('Erro ao buscar pedidos'));
    }
  }

  async countBySellerId(sellerId: string): RepositoryResponse<number> {
    try {
      return right(await this.prisma.order.count({ where: { sellerId } }));
    } catch {
      return left(new DatabaseError('Erro ao contar pedidos'));
    }
  }

  async countByBuyerId(buyerId: string): RepositoryResponse<number> {
    try {
      return right(await this.prisma.order.count({ where: { buyerId } }));
    } catch {
      return left(new DatabaseError('Erro ao contar pedidos'));
    }
  }

  async update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown> {
    try {
      return right(await this.prisma.order.update({ where: { id }, data }));
    } catch {
      return left(new DatabaseError('Erro ao atualizar pedido'));
    }
  }

  async createOrderWithReservation(data: CreateOrderTxData): RepositoryResponse<{ id: string }> {
    // Sentinel strings for expected business-rule failures inside the Prisma transaction.
    // Using string sentinels (not AppError instances) avoids instanceof checks on caught errors.
    const PRODUCT_NOT_FOUND = 'PRODUCT_NOT_FOUND';
    const OUT_OF_STOCK = 'OUT_OF_STOCK';
    const PRODUCT_UNAVAILABLE = 'PRODUCT_UNAVAILABLE';

    try {
      const order = await this.prisma.$transaction(async (tx) => {
        const products = await tx.$queryRaw<Product[]>`
          SELECT * FROM "Product" WHERE id = ${data.productId} FOR UPDATE
        `;
        const current = products[0];
        if (!current) {
          throw new Error(PRODUCT_NOT_FOUND);
        }
        if (current.status !== 'ACTIVE') {
          throw new Error(PRODUCT_UNAVAILABLE);
        }

        if (current.quantity > 1) {
          if (current.quantity <= current.soldCount) {
            throw new Error(OUT_OF_STOCK);
          }
          const newSoldCount = current.soldCount + 1;
          await tx.product.update({
            where: { id: data.productId },
            data: {
              soldCount: newSoldCount,
              ...(newSoldCount >= current.quantity ? { status: 'SOLD' as const } : {}),
            },
          });
        } else {
          const reserveResult = await tx.product.updateMany({
            where: { id: data.productId, status: 'ACTIVE' },
            data: { status: 'PAUSED' },
          });
          if (reserveResult.count === 0) {
            throw new Error(PRODUCT_UNAVAILABLE);
          }
        }

        const created = await tx.order.create({
          data: {
            buyer: { connect: { id: data.buyerId } },
            seller: { connect: { id: data.sellerId } },
            product: { connect: { id: data.productId } },
            amount: data.amount,
            platformFee: data.platformFee,
            sellerAmount: data.sellerAmount,
            status: 'PENDING',
            escrowStatus: 'HELD',
          },
          select: { id: true },
        });

        await tx.chatMessage.create({
          data: {
            orderId: created.id,
            senderId: data.buyerId,
            content: 'Pedido criado! Aproveite para combinar os detalhes da entrega.',
          },
        });

        return created;
      });

      return right(order);
    } catch (e) {
      if (e instanceof Error) {
        if (e.message === 'PRODUCT_NOT_FOUND') return left(new NotFoundError('Produto'));
        if (e.message === 'OUT_OF_STOCK') return left(new BadRequestError('Produto sem estoque'));
        if (e.message === 'PRODUCT_UNAVAILABLE') return left(new BadRequestError('Produto não está mais disponível'));
      }
      return left(new DatabaseError('Erro ao criar pedido'));
    }
  }

  async confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: data.orderId,
            escrowStatus: 'HELD',
            status: { in: ['CONFIRMED', 'DELIVERED'] },
          },
          data: {
            status: 'COMPLETED',
            escrowStatus: 'RELEASED',
            deliveryConfirmedAt: new Date(),
          },
        });
        if (claimed.count === 0) {
          return;
        }

        await applyWalletDelta(
          tx,
          data.sellerId,
          {
            pendingBalance: -data.sellerAmount,
            availableBalance: data.sellerAmount,
            totalEarned: data.sellerAmount,
          },
          { reason: WalletEntryReason.SALE_RELEASED, orderId: data.orderId },
        );

        await tx.transaction.update({
          where: { orderId: data.orderId },
          data: { status: 'RELEASED', releasedAt: new Date() },
        });
      });
      return right(void 0);
    } catch {
      return left(new DatabaseError('Erro ao confirmar entrega'));
    }
  }

  async cancelOrder(data: CancelOrderTxData): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: { id: data.orderId, status: { notIn: ['CANCELLED', 'COMPLETED'] } },
          data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
        });
        if (claimed.count === 0) {
          return;
        }

        const product = await tx.product.findUnique({
          where: { id: data.productId },
          select: { quantity: true },
        });

        if ((product?.quantity ?? 1) > 1) {
          await tx.product.updateMany({
            where: { id: data.productId, soldCount: { gte: data.orderQuantity } },
            data: { soldCount: { decrement: data.orderQuantity } },
          });
          await tx.product.updateMany({
            where: { id: data.productId, status: 'SOLD' },
            data: { status: 'ACTIVE' },
          });
        } else {
          await tx.product.update({
            where: { id: data.productId },
            data: { status: 'ACTIVE' },
          });
        }

        if (data.status === 'CONFIRMED') {
          await applyWalletDelta(
            tx,
            data.buyerId,
            { availableBalance: data.amount },
            { reason: WalletEntryReason.REFUND, orderId: data.orderId },
          );
          await applyWalletDelta(
            tx,
            data.sellerId,
            { pendingBalance: -data.sellerAmount },
            { reason: WalletEntryReason.HOLD_RELEASED, orderId: data.orderId },
          );
        }
      });
      return right(void 0);
    } catch {
      return left(new DatabaseError('Erro ao cancelar pedido'));
    }
  }

  async confirm(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    try {
      const client = tx ?? this.prisma;
      await client.order.update({
        where: { id: orderId },
        data: { status: 'CONFIRMED', escrowStatus: 'HELD' },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to confirm order'));
    }
  }

  async cancel(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    try {
      const client = tx ?? this.prisma;
      await client.order.update({
        where: { id: orderId },
        data: { status: 'CANCELLED' },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to cancel order'));
    }
  }
}
