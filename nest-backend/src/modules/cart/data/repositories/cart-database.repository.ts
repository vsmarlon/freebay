import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CartRepository } from '../../domain/repositories/cart.repository';
import { CartItemPayload, ProductBrief, CART_ITEM_INCLUDE } from '../../types/cart.types';

@Injectable()
export class CartDatabaseRepository implements CartRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findProductById(productId: string): RepositoryResponse<ProductBrief | null> {
    try {
      const product = await this.prisma.product.findUnique({
        where: { id: productId },
        select: { id: true, sellerId: true, status: true, price: true },
      });
      return right(product);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar produto'));
    }
  }

  async findItem(userId: string, productId: string): RepositoryResponse<{ id: string; quantity: number } | null> {
    try {
      const item = await this.prisma.cartItem.findUnique({
        where: { userId_productId: { userId, productId } },
        select: { id: true, quantity: true },
      });
      return right(item);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar item no carrinho'));
    }
  }

  async addOrIncrement(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }> {
    try {
      const existing = await this.prisma.cartItem.findUnique({
        where: { userId_productId: { userId, productId } },
      });

      if (existing) {
        const nextQuantity = Math.min(existing.quantity + quantity, 10);
        const item = await this.prisma.cartItem.update({
          where: { userId_productId: { userId, productId } },
          data: { quantity: nextQuantity },
          select: { id: true, quantity: true },
        });
        return right(item);
      }

      const item = await this.prisma.cartItem.create({
        data: {
          user: { connect: { id: userId } },
          product: { connect: { id: productId } },
          quantity: Math.min(Math.max(quantity, 1), 10),
        },
        select: { id: true, quantity: true },
      });
      return right(item);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao adicionar item ao carrinho'));
    }
  }

  async updateQuantity(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }> {
    try {
      const item = await this.prisma.cartItem.update({
        where: { userId_productId: { userId, productId } },
        data: { quantity },
        select: { id: true, quantity: true },
      });
      return right(item);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar quantidade'));
    }
  }

  async remove(userId: string, productId: string): RepositoryResponse<void> {
    try {
      await this.prisma.cartItem.delete({
        where: { userId_productId: { userId, productId } },
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover item do carrinho'));
    }
  }

  async clear(userId: string): RepositoryResponse<void> {
    try {
      await this.prisma.cartItem.deleteMany({ where: { userId } });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao limpar carrinho'));
    }
  }

  async getUserCart(userId: string): RepositoryResponse<CartItemPayload[]> {
    try {
      const items = await this.prisma.cartItem.findMany({
        where: { userId, product: { status: 'ACTIVE', deletedAt: null } },
        orderBy: { createdAt: 'desc' },
        include: CART_ITEM_INCLUDE,
      });
      return right(items as CartItemPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar carrinho'));
    }
  }

  async findUserCpf(userId: string): RepositoryResponse<string | null> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { cpf: true },
      });
      return right(user?.cpf ?? null);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
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
        return left(new AppError('BAD_REQUEST', 'Um ou mais produtos não estão mais disponíveis'));
      }
      return left(new AppError('DB_ERROR', 'Erro ao criar pedido'));
    }
  }

  async rollbackOrderReservation(orderId: string, productId: string): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.order.delete({ where: { id: orderId } });

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
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao reverter pedido'));
    }
  }
}
