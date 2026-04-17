import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class PrismaCartRepository {
  constructor(private prisma: PrismaService) {}

  async findProductById(productId: string) {
    return this.prisma.product.findUnique({
      where: { id: productId },
      select: {
        id: true,
        sellerId: true,
        status: true,
        price: true,
      },
    });
  }

  async findItem(userId: string, productId: string) {
    return this.prisma.cartItem.findUnique({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
    });
  }

  async addOrIncrement(userId: string, productId: string, quantity: number) {
    const existing = await this.findItem(userId, productId);

    if (existing) {
      const nextQuantity = Math.min(existing.quantity + quantity, 10);
      return this.prisma.cartItem.update({
        where: {
          userId_productId: {
            userId,
            productId,
          },
        },
        data: {
          quantity: nextQuantity,
        },
      });
    }

    return this.prisma.cartItem.create({
      data: {
        user: { connect: { id: userId } },
        product: { connect: { id: productId } },
        quantity: Math.min(Math.max(quantity, 1), 10),
      },
    });
  }

  async updateQuantity(userId: string, productId: string, quantity: number) {
    return this.prisma.cartItem.update({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
      data: {
        quantity,
      },
    });
  }

  async remove(userId: string, productId: string) {
    return this.prisma.cartItem.delete({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
    });
  }

  async clear(userId: string) {
    return this.prisma.cartItem.deleteMany({
      where: { userId },
    });
  }

  async getUserCart(userId: string) {
    return this.prisma.cartItem.findMany({
      where: {
        userId,
        product: {
          status: 'ACTIVE',
          deletedAt: null,
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        product: {
          include: {
            seller: {
              select: {
                id: true,
                displayName: true,
                avatarUrl: true,
                isVerified: true,
              },
            },
            images: {
              orderBy: { order: 'asc' },
              take: 1,
            },
          },
        },
      },
    });
  }
}
