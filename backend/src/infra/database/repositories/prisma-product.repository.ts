import { IProductRepository } from '@/domain/repositories';
import { ProductEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';
import { Prisma } from '@prisma/client';

export class PrismaProductRepository implements IProductRepository {
  async findById(id: string): Promise<ProductEntity | null> {
    return prisma.product.findFirst({
      where: { id, deletedAt: null },
    });
  }

  async findBySellerId(sellerId: string): Promise<ProductEntity[]> {
    return prisma.product.findMany({
      where: { sellerId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findAll(params: {
    cursor?: string;
    limit?: number;
    search?: string;
    category?: string;
    minPrice?: number;
    maxPrice?: number;
  }): Promise<ProductEntity[]> {
    const limit = params.limit ?? 20;

    const where: Prisma.ProductWhereInput = {
      deletedAt: null,
      status: 'ACTIVE',
    };

    if (params.search) {
      where.OR = [
        { title: { contains: params.search, mode: 'insensitive' } },
        { description: { contains: params.search, mode: 'insensitive' } },
      ];
    }

    if (params.category) {
      where.categoryId = params.category;
    }

    if (params.minPrice !== undefined || params.maxPrice !== undefined) {
      where.price = {
        ...(params.minPrice !== undefined ? { gte: params.minPrice } : {}),
        ...(params.maxPrice !== undefined ? { lte: params.maxPrice } : {}),
      };
    }

    return prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
    });
  }

  async create(
    data: Omit<ProductEntity, 'id' | 'createdAt' | 'updatedAt' | 'deletedAt'>,
  ): Promise<ProductEntity> {
    return prisma.product.create({ data });
  }

  async update(id: string, data: Partial<ProductEntity>): Promise<ProductEntity> {
    return prisma.product.update({ where: { id }, data });
  }

  async softDelete(id: string): Promise<void> {
    await prisma.product.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'DELETED' },
    });
  }
}
