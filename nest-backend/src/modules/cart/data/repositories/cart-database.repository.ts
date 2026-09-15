import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import {
  CartItemPayload,
  ProductBrief,
  ReserveOrderInput,
  CART_ITEM_INCLUDE,
  PRODUCT_UNAVAILABLE,
} from '../../types/cart.types';
import { Prisma, Product } from '@prisma/client';

@Injectable()
export class CartDatabaseRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findProductById(productId: string): RepositoryResponse<ProductBrief | null> {
    return this.safeRun(() => this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true, sellerId: true, status: true, price: true },
    }), 'Erro ao buscar produto');
  }

  async findItem(userId: string, productId: string): RepositoryResponse<{ id: string; quantity: number } | null> {
    return this.safeRun(() => this.prisma.cartItem.findUnique({
      where: { userId_productId: { userId, productId } },
      select: { id: true, quantity: true },
    }), 'Erro ao buscar item no carrinho');
  }

  async addOrIncrement(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }> {
    return this.safeRun(async () => {
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
    return this.safeRun(() => this.prisma.cartItem.update({
      where: { userId_productId: { userId, productId } },
      data: { quantity },
      select: { id: true, quantity: true },
    }), 'Erro ao atualizar quantidade');
  }

  async remove(userId: string, productId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.cartItem.delete({ where: { userId_productId: { userId, productId } } });
    }, 'Erro ao remover item do carrinho');
  }

  async clear(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await (tx ?? this.prisma).cartItem.deleteMany({ where: { userId } });
    }, 'Erro ao limpar carrinho');
  }

  async getUserCart(userId: string): RepositoryResponse<CartItemPayload[]> {
    return this.safeRun(async () => {
      const items = await this.prisma.cartItem.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: CART_ITEM_INCLUDE,
      });
      return items as CartItemPayload[];
    }, 'Erro ao buscar carrinho');
  }

  async findUserCpf(userId: string): RepositoryResponse<string | null> {
    return this.safeRun(async () => {
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
    if (!current || current.status !== 'ACTIVE') {
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

    return tx.order.create({
      data: {
        buyer: { connect: { id: data.userId } },
        seller: { connect: { id: data.sellerId } },
        product: { connect: { id: data.productId } },
        quantity: data.quantity,
        amount: data.amount,
        platformFee: data.platformFee,
        sellerAmount: data.sellerAmount,
        status: 'PENDING',
        escrowStatus: 'HELD',
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
      where: { id: orderId, status: { notIn: ['CANCELLED', 'COMPLETED'] } },
      data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
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
          ...(current.status === 'SOLD' && newSoldCount < current.quantity
            ? { status: 'ACTIVE' as const }
            : {}),
        },
      });
    } else {
      await tx.product.updateMany({
        where: { id: productId, status: 'PAUSED' },
        data: { status: 'ACTIVE' },
      });
    }
  }
}
