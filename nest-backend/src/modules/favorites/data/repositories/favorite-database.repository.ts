import { Injectable } from '@nestjs/common';
import { PrismaClient, Favorite, Product } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FavoriteRepository } from '../../domain/repositories/favorite.repository';
import { FavoriteWithProduct } from '../../types/favorite.types';
import { SELLER_SELECT_FULL } from '@/shared/utils/prisma-selects';

@Injectable()
export class FavoriteDatabaseRepository implements FavoriteRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findProductById(productId: string): RepositoryResponse<Pick<Product, 'id' | 'sellerId' | 'status'> | null> {
    try {
      return right(await this.prisma.product.findUnique({
        where: { id: productId },
        select: { id: true, sellerId: true, status: true },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar produto'));
    }
  }

  async findByUserAndProduct(userId: string, productId: string): RepositoryResponse<Favorite | null> {
    try {
      return right(await this.prisma.favorite.findUnique({
        where: { userId_productId: { userId, productId } },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar favorito'));
    }
  }

  async create(userId: string, productId: string): RepositoryResponse<Favorite> {
    try {
      return right(await this.prisma.favorite.create({
        data: {
          user: { connect: { id: userId } },
          product: { connect: { id: productId } },
        },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar favorito'));
    }
  }

  async delete(userId: string, productId: string): RepositoryResponse<Favorite> {
    try {
      return right(await this.prisma.favorite.delete({
        where: { userId_productId: { userId, productId } },
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover favorito'));
    }
  }

  async getUserFavorites(userId: string): RepositoryResponse<FavoriteWithProduct[]> {
    try {
      return right(await this.prisma.favorite.findMany({
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
      }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar favoritos'));
    }
  }
}
