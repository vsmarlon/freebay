import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { CartRepository } from '../../domain/repositories/cart.repository';
import { CartItemPayload, ProductBrief, CART_ITEM_INCLUDE } from '../../types/cart.types';

@Injectable()
export class CartDatabaseRepository extends BasePrismaRepository implements CartRepository {
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

  async clear(userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.cartItem.deleteMany({ where: { userId } });
    }, 'Erro ao limpar carrinho');
  }

  async getUserCart(userId: string): RepositoryResponse<CartItemPayload[]> {
    return this.safeRun(async () => {
      const items = await this.prisma.cartItem.findMany({
        where: { userId, product: { status: 'ACTIVE', deletedAt: null } },
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

  async createOrderFromCheckout(data: {
    userId: string;
    sellerId: string;
    productId: string;
    amount: number;
    platformFee: number;
    sellerAmount: number;
  }): RepositoryResponse<{ id: string }> {
    try {
      const order = await this.prisma.$transaction(async (tx) => {
        const currentProduct = await tx.product.findUnique({
          where: { id: data.productId },
          select: { quantity: true, soldCount: true, status: true },
        });

        if (!currentProduct || currentProduct.status !== 'ACTIVE') {
          throw new Error('PRODUCT_UNAVAILABLE');
        }

        if (currentProduct.quantity > 1) {
          if (currentProduct.quantity <= currentProduct.soldCount) {
            throw new Error('PRODUCT_UNAVAILABLE');
          }
          const newSoldCount = currentProduct.soldCount + 1;
          await tx.product.update({
            where: { id: data.productId },
            data: {
              soldCount: newSoldCount,
              ...(newSoldCount >= currentProduct.quantity ? { status: 'SOLD' as const } : {}),
            },
          });
        } else {
          const reserveResult = await tx.product.updateMany({
            where: { id: data.productId, status: 'ACTIVE' },
            data: { status: 'PAUSED' },
          });
          if (reserveResult.count === 0) {
            throw new Error('PRODUCT_UNAVAILABLE');
          }
        }

        return tx.order.create({
          data: {
            buyer: { connect: { id: data.userId } },
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
      });
      return right(order);
    } catch (e) {
      if ((e as Error).message === 'PRODUCT_UNAVAILABLE') {
        return left(new BadRequestError('Um ou mais produtos não estão mais disponíveis'));
      }
      return left(new DatabaseError('Erro ao criar pedido'));
    }
  }

  async rollbackOrderReservation(orderId: string, productId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.$transaction(async (tx) => {
        await tx.order.update({ where: { id: orderId }, data: { status: 'CANCELLED' } });
        const currentProduct = await tx.product.findUnique({
          where: { id: productId },
          select: { quantity: true, soldCount: true, status: true },
        });
        if (currentProduct && currentProduct.quantity > 1) {
          const newSoldCount = currentProduct.soldCount - 1;
          await tx.product.update({
            where: { id: productId },
            data: {
              soldCount: newSoldCount >= 0 ? newSoldCount : 0,
              ...(currentProduct.status === 'SOLD' && newSoldCount < currentProduct.quantity ? { status: 'ACTIVE' as const } : {}),
            },
          });
        } else {
          await tx.product.updateMany({
            where: { id: productId, status: 'PAUSED' },
            data: { status: 'ACTIVE' },
          });
        }
      });
    }, 'Erro ao reverter pedido');
  }
}
