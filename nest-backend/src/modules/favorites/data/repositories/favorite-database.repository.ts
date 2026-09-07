import { Injectable } from '@nestjs/common';
import { Favorite, Product } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { FavoriteWithProduct } from '../../types/favorite.types';
import { SELLER_SELECT_FULL } from '@/shared/utils/prisma-selects';

@Injectable()
export class FavoriteDatabaseRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findProductById(productId: string): RepositoryResponse<Pick<Product, 'id' | 'sellerId' | 'status'> | null> {
    return this.safeRun(() => this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true, sellerId: true, status: true },
    }), 'Erro ao buscar produto');
  }

  async findByUserAndProduct(userId: string, productId: string): RepositoryResponse<Favorite | null> {
    return this.safeRun(() => this.prisma.favorite.findUnique({
      where: { userId_productId: { userId, productId } },
    }), 'Erro ao buscar favorito');
  }

  async create(userId: string, productId: string): RepositoryResponse<Favorite> {
    return this.safeRun(() => this.prisma.favorite.create({
      data: {
        user: { connect: { id: userId } },
        product: { connect: { id: productId } },
      },
    }), 'Erro ao criar favorito');
  }

  async delete(userId: string, productId: string): RepositoryResponse<Favorite> {
    return this.safeRun(() => this.prisma.favorite.delete({
      where: { userId_productId: { userId, productId } },
    }), 'Erro ao remover favorito');
  }

  async getUserFavorites(userId: string): RepositoryResponse<FavoriteWithProduct[]> {
    return this.safeRun(() => this.prisma.favorite.findMany({
      where: {
        userId,
        product: { status: 'ACTIVE', deletedAt: null },
      },
      orderBy: { createdAt: 'desc' },
      include: {
        product: {
          include: {
            seller: { select: SELLER_SELECT_FULL },
            images: { orderBy: { order: 'asc' }, take: 1 },
          },
        },
      },
    }), 'Erro ao buscar favoritos');
  }
}
