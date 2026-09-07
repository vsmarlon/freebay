import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDetailPayload, ProductListPayload, FindManyParams, ProductSort, PRODUCT_DETAIL_INCLUDE, PRODUCT_LIST_INCLUDE } from '../../types/product.types';

@Injectable()
export class ProductDatabaseRepository implements ProductRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    try {
      const product = await this.prisma.product.findUnique({
        where: { id },
        include: PRODUCT_DETAIL_INCLUDE,
      });
      if (product && (product.status === 'DELETED' || product.deletedAt !== null)) {
        return right(null);
      }
      return right(product as ProductDetailPayload | null);
    } catch (e) {
      return left(new DatabaseError((e as Error).message));
    }
  }

  async findBySellerId(sellerId: string) {
    try {
      const products = await this.prisma.product.findMany({
        where: { sellerId, status: 'ACTIVE', deletedAt: null },
        orderBy: { createdAt: 'desc' },
        include: PRODUCT_LIST_INCLUDE,
      });
      return right(products as ProductListPayload[]);
    } catch (e) {
      return left(new DatabaseError((e as Error).message));
    }
  }

  async findMany(params: FindManyParams) {
    try {
      const { cursor, limit = 20, search, categoryId, minPrice, maxPrice, condition, sort = 'recent' } = params;
      const where: Prisma.ProductWhereInput = { status: 'ACTIVE', deletedAt: null };
      if (search) {
        where.OR = [
          { title: { contains: search, mode: 'insensitive' } },
          { description: { contains: search, mode: 'insensitive' } },
        ];
      }
      if (categoryId) {
        const categoryIds = await this.collectCategoryTree(categoryId);
        where.categoryId = categoryIds.length > 1 ? { in: categoryIds } : categoryId;
      }
      if (condition) where.condition = condition;
      if (minPrice || maxPrice) {
        const priceFilter: Prisma.IntFilter = {};
        if (minPrice) priceFilter.gte = minPrice;
        if (maxPrice) priceFilter.lte = maxPrice;
        where.price = priceFilter;
      }

      const products = await this.prisma.product.findMany({
        where,
        orderBy: this.buildOrderBy(sort),
        take: limit,
        ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
        include: PRODUCT_LIST_INCLUDE,
      });
      return right(products as ProductListPayload[]);
    } catch (e) {
      return left(new DatabaseError((e as Error).message));
    }
  }

  private buildOrderBy(sort: ProductSort): Prisma.ProductOrderByWithRelationInput[] {
    switch (sort) {
      case 'price_asc':
        return [{ price: 'asc' }, { id: 'asc' }];
      case 'price_desc':
        return [{ price: 'desc' }, { id: 'asc' }];
      case 'popular':
        return [{ soldCount: 'desc' }, { id: 'asc' }];
      default:
        return [{ createdAt: 'desc' }, { id: 'asc' }];
    }
  }

  private static categoryCache: { tree: Map<string, string[]>; expiry: number } | null = null;

  private async collectCategoryTree(rootId: string): Promise<string[]> {
    const now = Date.now();
    if (
      !ProductDatabaseRepository.categoryCache ||
      ProductDatabaseRepository.categoryCache.expiry < now
    ) {
      try {
        const allCategories = await this.prisma.category.findMany({
          select: { id: true, parentId: true },
        });
        const parentToChildren = new Map<string, string[]>();
        for (const cat of allCategories) {
          if (cat.parentId) {
            const list = parentToChildren.get(cat.parentId) ?? [];
            list.push(cat.id);
            parentToChildren.set(cat.parentId, list);
          }
        }
        ProductDatabaseRepository.categoryCache = {
          tree: parentToChildren,
          expiry: now + 5 * 60 * 1000, // 5 min TTL
        };
      } catch {
        return [rootId];
      }
    }

    const parentToChildren = ProductDatabaseRepository.categoryCache.tree;
    const collected = new Set<string>([rootId]);
    const queue = [rootId];

    while (queue.length > 0) {
      const curr = queue.shift()!;
      const children = parentToChildren.get(curr);
      if (children) {
        for (const childId of children) {
          if (!collected.has(childId)) {
            collected.add(childId);
            queue.push(childId);
          }
        }
      }
    }

    return [...collected];
  }

  async create(data: Prisma.ProductCreateInput) {
    try {
      const product = await this.prisma.product.create({ data, include: PRODUCT_DETAIL_INCLUDE });
      return right(product as ProductDetailPayload);
    } catch (e) {
      return left(new DatabaseError((e as Error).message));
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
      return left(new DatabaseError((e as Error).message));
    }
  }

  async delete(id: string) {
    try {
      await this.prisma.product.update({
        where: { id },
        data: { status: 'DELETED', deletedAt: new Date() },
      });
      return right(void 0);
    } catch (e) {
      return left(new DatabaseError((e as Error).message));
    }
  }

  async updateInventoryOnSale(productId: string, tx?: Prisma.TransactionClient) {
    try {
      const client = tx ?? this.prisma;
      const product = await client.product.findUnique({ where: { id: productId } });
      if (!product) return left(new DatabaseError('Product not found'));

      if (product.quantity > 1 && product.soldCount < product.quantity) {
        return right(undefined);
      }

      await client.product.updateMany({
        where: { id: productId, status: { not: 'SOLD' } },
        data: { status: 'SOLD' },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to update inventory on sale'));
    }
  }

  async restoreInventoryOnExpiry(productId: string, quantity: number, tx?: Prisma.TransactionClient) {
    try {
      const client = tx ?? this.prisma;
      const product = await client.product.findUnique({ where: { id: productId } });
      if (!product) return left(new DatabaseError('Product not found'));

      if (product.quantity > 1) {
        await client.product.updateMany({
          where: { id: productId, soldCount: { gte: quantity } },
          data: { soldCount: { decrement: quantity } },
        });
        await client.product.updateMany({
          where: { id: productId, status: 'SOLD' },
          data: { status: 'ACTIVE' },
        });
      } else {
        await client.product.updateMany({
          where: { id: productId, status: 'PAUSED' },
          data: { status: 'ACTIVE' },
        });
      }
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to restore inventory on expiry'));
    }
  }
}
