import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaProductRepository {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.product.findUnique({
      where: { id },
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
        category: true,
        images: { orderBy: { order: 'asc' } },
      },
    });
  }

  async findBySellerId(sellerId: string) {
    return this.prisma.product.findMany({
      where: { sellerId, status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
      include: { images: { orderBy: { order: 'asc' }, take: 1 } },
    });
  }

  async findMany(params: {
    cursor?: string;
    limit?: number;
    search?: string;
    categoryId?: string;
    minPrice?: number;
    maxPrice?: number;
  }) {
    const { cursor, limit = 20, search, categoryId, minPrice, maxPrice } = params;

    const where: Prisma.ProductWhereInput = { status: 'ACTIVE' };
    if (search) where.title = { contains: search, mode: 'insensitive' };
    if (categoryId) where.categoryId = categoryId;
    if (minPrice || maxPrice) {
      const priceFilter: Prisma.IntFilter = {};
      if (minPrice) priceFilter.gte = minPrice;
      if (maxPrice) priceFilter.lte = maxPrice;
      where.price = priceFilter;
    }

    return this.prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
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
        images: { orderBy: { order: 'asc' }, take: 1 },
      },
    });
  }

  async create(data: Prisma.ProductCreateInput) {
    return this.prisma.product.create({ data, include: { images: true } });
  }

  async update(id: string, data: Prisma.ProductUpdateInput) {
    return this.prisma.product.update({
      where: { id },
      data,
      include: { images: true },
    });
  }

  async delete(id: string) {
    return this.prisma.product.update({ where: { id }, data: { status: 'DELETED' } });
  }
}
