import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class PrismaFavoriteRepository {
  constructor(private prisma: PrismaService) {}

  async findProductById(productId: string) {
    return this.prisma.product.findUnique({
      where: { id: productId },
      select: {
        id: true,
        sellerId: true,
        status: true,
      },
    });
  }

  async findByUserAndProduct(userId: string, productId: string) {
    return this.prisma.favorite.findUnique({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
    });
  }

  async create(userId: string, productId: string) {
    return this.prisma.favorite.create({
      data: {
        user: { connect: { id: userId } },
        product: { connect: { id: productId } },
      },
    });
  }

  async delete(userId: string, productId: string) {
    return this.prisma.favorite.delete({
      where: {
        userId_productId: {
          userId,
          productId,
        },
      },
    });
  }

  async getUserFavorites(userId: string) {
    return this.prisma.favorite.findMany({
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
                reputationScore: true,
                totalReviews: true,
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
