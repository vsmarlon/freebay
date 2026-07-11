import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { OrderRepository, CreateOrderTxData, ConfirmDeliveryData, CancelOrderTxData, ProductForOrder } from '../../domain/repositories/order.repository';
import { OrderFullPayload, OrderProductPayload, ORDER_INCLUDE_FULL, ORDER_INCLUDE_PRODUCT } from '../../types/order.types';
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
      return left(new AppError('DB_ERROR', 'Erro ao buscar pedido'));
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
      return left(new AppError('DB_ERROR', 'Erro ao buscar produto'));
    }
  }

  async findByBuyerId(buyerId: string): RepositoryResponse<OrderProductPayload[]> {
    try {
      const orders = await this.prisma.order.findMany({
        where: { buyerId },
        orderBy: { createdAt: 'desc' },
        include: ORDER_INCLUDE_PRODUCT,
      });
      return right(orders as OrderProductPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar pedidos'));
    }
  }

  async findBySellerId(sellerId: string): RepositoryResponse<OrderProductPayload[]> {
    try {
      const orders = await this.prisma.order.findMany({
        where: { sellerId },
        orderBy: { createdAt: 'desc' },
        include: ORDER_INCLUDE_PRODUCT,
      });
      return right(orders as OrderProductPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar pedidos'));
    }
  }

  async countBySellerId(sellerId: string): RepositoryResponse<number> {
    try {
      return right(await this.prisma.order.count({ where: { sellerId } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao contar pedidos'));
    }
  }

  async countByBuyerId(buyerId: string): RepositoryResponse<number> {
    try {
      return right(await this.prisma.order.count({ where: { buyerId } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao contar pedidos'));
    }
  }

  async update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown> {
    try {
      return right(await this.prisma.order.update({ where: { id }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar pedido'));
    }
  }

  async createOrderWithReservation(data: CreateOrderTxData): RepositoryResponse<{ id: string }> {
    try {
      const product = await this.prisma.product.findUnique({ where: { id: data.productId } });
      if (!product) return left(new AppError('NOT_FOUND', 'Produto não encontrado', 404));

      const order = await this.prisma.$transaction(async (tx) => {
        if (product.quantity > 1) {
          const products = await tx.$queryRaw<Product[]>`
            SELECT * FROM "Product" WHERE id = ${data.productId} FOR UPDATE
          `;
          const current = products[0];
          if (!current || current.quantity <= current.soldCount) {
            throw new AppError('BAD_REQUEST', 'Produto sem estoque');
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
            throw new AppError('BAD_REQUEST', 'Produto não está mais disponível');
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
      if (e instanceof AppError) return left(e);
      return left(new AppError('DB_ERROR', 'Erro ao criar pedido'));
    }
  }

  async confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: data.orderId },
          data: {
            status: 'COMPLETED',
            escrowStatus: 'RELEASED',
            deliveryConfirmedAt: new Date(),
          },
        });

        const wallet = await tx.wallet.findUnique({ where: { userId: data.sellerId } });
        if (wallet) {
          await tx.wallet.update({
            where: { userId: data.sellerId },
            data: {
              pendingBalance: { decrement: data.sellerAmount },
              availableBalance: { increment: data.sellerAmount },
              totalEarned: { increment: data.sellerAmount },
            },
          });
        }

        await tx.transaction.update({
          where: { orderId: data.orderId },
          data: { status: 'RELEASED', releasedAt: new Date() },
        });
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao confirmar entrega'));
    }
  }

  async activateEscrow(orderId: string, sellerId: string, sellerAmount: number): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: orderId },
          data: { status: 'CONFIRMED', escrowStatus: 'HELD' },
        });

        const wallet = await tx.wallet.findUnique({ where: { userId: sellerId } });
        if (wallet) {
          await tx.wallet.update({
            where: { userId: sellerId },
            data: { pendingBalance: { increment: sellerAmount } },
          });
        }
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao ativar escrow'));
    }
  }

  async cancelOrder(data: CancelOrderTxData): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: data.orderId },
          data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
        });

        if (data.quantity > 1) {
          const current = await tx.product.findUnique({ where: { id: data.productId } });
          if (current) {
            const newSoldCount = Math.max(current.soldCount - 1, 0);
            await tx.product.update({
              where: { id: data.productId },
              data: {
                soldCount: newSoldCount,
                ...(current.status === 'SOLD' && newSoldCount < current.quantity ? { status: 'ACTIVE' as const } : {}),
              },
            });
          }
        } else {
          await tx.product.update({
            where: { id: data.productId },
            data: { status: 'ACTIVE' },
          });
        }

        if (data.status === 'CONFIRMED') {
          const wallet = await tx.wallet.findUnique({ where: { userId: data.buyerId } });
          if (wallet) {
            await tx.wallet.update({
              where: { userId: data.buyerId },
              data: { availableBalance: { increment: data.amount } },
            });
          }
          const sellerWallet = await tx.wallet.findUnique({ where: { userId: data.sellerId } });
          if (sellerWallet) {
            await tx.wallet.update({
              where: { userId: data.sellerId },
              data: { pendingBalance: { decrement: data.sellerAmount } },
            });
          }
        }
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao cancelar pedido'));
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
