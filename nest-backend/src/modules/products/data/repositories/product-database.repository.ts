import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDetailPayload, ProductListPayload, FindManyParams, PRODUCT_DETAIL_INCLUDE, PRODUCT_LIST_INCLUDE } from '../../types/product.types';

@Injectable()
export class ProductDatabaseRepository implements ProductRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    try {
      const product = await this.prisma.product.findUnique({
        where: { id },
        include: PRODUCT_DETAIL_INCLUDE,
      });
      return right(product as ProductDetailPayload | null);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }

  async findBySellerId(sellerId: string) {
    try {
      const products = await this.prisma.product.findMany({
        where: { sellerId, status: 'ACTIVE' },
        orderBy: { createdAt: 'desc' },
        include: PRODUCT_LIST_INCLUDE,
      });
      return right(products as ProductListPayload[]);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }

  async findMany(params: FindManyParams) {
    try {
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

      const products = await this.prisma.product.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
        include: PRODUCT_LIST_INCLUDE,
      });
      return right(products as ProductListPayload[]);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }

  async create(data: Prisma.ProductCreateInput) {
    try {
      const product = await this.prisma.product.create({ data, include: PRODUCT_DETAIL_INCLUDE });
      return right(product as ProductDetailPayload);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }

  async update(id: string, data: Prisma.ProductUpdateInput) {
    try {
      const product = await this.prisma.product.update({
        where: { id },
        data,
        include: PRODUCT_DETAIL_INCLUDE,
      });
      return right(product as ProductDetailPayload);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }

  async delete(id: string) {
    try {
      await this.prisma.product.update({ where: { id }, data: { status: 'DELETED' } });
      return right(void 0);
    } catch (e) {
      return left(new AppError('DATABASE_ERROR', (e as Error).message));
    }
  }
}
