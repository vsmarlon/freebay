import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import {
  CartItemPayload,
  ProductBrief,
  ReserveOrderInput,
  CART_ITEM_INCLUDE,
  PRODUCT_UNAVAILABLE,
} from '../../types/cart.types';
import {
  EscrowStatus,
  OrderStatus,
  Prisma,
  Product,
  ProductStatus,
} from '@prisma/client';

@Injectable()
export class CartDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findProductById(productId: string): RepositoryResponse<ProductBrief | null> {
    return repositoryResponse(() => this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true, sellerId: true, status: true, price: true },
    }), 'Erro ao buscar produto');
  }

  async findItem(userId: string, productId: string): RepositoryResponse<{ id: string; quantity: number } | null> {
    return repositoryResponse(() => this.prisma.cartItem.findUnique({
      where: { userId_productId: { userId, productId } },
      select: { id: true, quantity: true },
    }), 'Erro ao buscar item no carrinho');
  }

  async addOrIncrement(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }> {
    return repositoryResponse(async () => {
      const existing = await this.prisma.cartItem.findUnique({
        where: { userId_productId: { userId, productId } },
      });
      if (existing) {
        return this.prisma.cartItem.update({
          where: { userId_productId: { userId, productId } },
          data: { quantity: Math.min(existing.quantity + quantity, 10) },
          select: { id: true, quantity: true },
        });
      }
      return this.prisma.cartItem.create({
        data: {
          user: { connect: { id: userId } },
          product: { connect: { id: productId } },
          quantity: Math.min(Math.max(quantity, 1), 10),
        },
        select: { id: true, quantity: true },
      });
    }, 'Erro ao adicionar item ao carrinho');
  }

  async updateQuantity(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }> {
    return repositoryResponse(() => this.prisma.cartItem.update({
      where: { userId_productId: { userId, productId } },
      data: { quantity },
      select: { id: true, quantity: true },
    }), 'Erro ao atualizar quantidade');
  }

  async remove(userId: string, productId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.cartItem.delete({ where: { userId_productId: { userId, productId } } });
    }, 'Erro ao remover item do carrinho');
  }

  async clear(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await (tx ?? this.prisma).cartItem.deleteMany({ where: { userId } });
    }, 'Erro ao limpar carrinho');
  }

  async getUserCart(userId: string): RepositoryResponse<CartItemPayload[]> {
    return repositoryResponse(async () => {
      const items = await this.prisma.cartItem.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: CART_ITEM_INCLUDE,
      });
      return items;
    }, 'Erro ao buscar carrinho');
  }

  async findUserCpf(userId: string): RepositoryResponse<string | null> {
    return repositoryResponse(async () => {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { cpf: true },
      });
      return user?.cpf ?? null;
    }, 'Erro ao buscar usuário');
  }

  async reserveAndCreateOrder(
    data: ReserveOrderInput,
    tx: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    const products = await tx.$queryRaw<Product[]>`
      SELECT * FROM "Product" WHERE id = ${data.productId} FOR UPDATE
    `;
    const current = products[0];
    if (!current || current.status !== ProductStatus.ACTIVE) {
      throw new Error(PRODUCT_UNAVAILABLE);
    }

    if (current.quantity > 1) {
      const availableStock = current.quantity - current.soldCount;
      if (availableStock < data.quantity) {
        throw new Error(PRODUCT_UNAVAILABLE);
      }
      const newSoldCount = current.soldCount + data.quantity;
      await tx.product.update({
        where: { id: data.productId },
        data: {
          soldCount: newSoldCount,
          ...(newSoldCount >= current.quantity ? { status: ProductStatus.SOLD } : {}),
        },
      });
    } else {
      const reserveResult = await tx.product.updateMany({
        where: { id: data.productId, status: ProductStatus.ACTIVE },
        data: { status: ProductStatus.PAUSED },
      });
      if (reserveResult.count === 0) {
        throw new Error(PRODUCT_UNAVAILABLE);
      }
    }

    return tx.order.create({
      data: {
        buyer: { connect: { id: data.userId } },
        seller: { connect: { id: data.sellerId } },
        product: { connect: { id: data.productId } },
        quantity: data.quantity,
        amount: data.amount,
        platformFee: data.platformFee,
        sellerAmount: data.sellerAmount,
        status: OrderStatus.PENDING,
        escrowStatus: EscrowStatus.HELD,
      },
      select: { id: true },
    });
  }

  async restoreOrderReservation(
    orderId: string,
    productId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    const claimed = await tx.order.updateMany({
      where: { id: orderId, status: { notIn: [OrderStatus.CANCELLED, OrderStatus.COMPLETED] } },
      data: { status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED },
    });
    if (claimed.count === 0) return;

    const order = await tx.order.findUnique({
      where: { id: orderId },
      select: { quantity: true },
    });
    const products = await tx.$queryRaw<Product[]>`
      SELECT * FROM "Product" WHERE id = ${productId} FOR UPDATE
    `;
    const current = products[0];
    if (!current) return;

    if (current.quantity > 1) {
      const newSoldCount = current.soldCount - (order?.quantity ?? 1);
      await tx.product.update({
        where: { id: productId },
        data: {
          soldCount: newSoldCount >= 0 ? newSoldCount : 0,
          ...(current.status === ProductStatus.SOLD && newSoldCount < current.quantity
            ? { status: ProductStatus.ACTIVE }
            : {}),
        },
      });
    } else {
      await tx.product.updateMany({
        where: { id: productId, status: ProductStatus.PAUSED },
        data: { status: ProductStatus.ACTIVE },
      });
    }
  }
}
