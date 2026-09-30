import { Injectable } from '@nestjs/common';
import { Prisma, ProductStatus } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';
import { FindManyParams, ProductSort, PRODUCT_DETAIL_INCLUDE, PRODUCT_LIST_INCLUDE } from '../../types/product.types';

@Injectable()
export class ProductDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findById(id: string) {
    return repositoryResponse(async () => {
      const product = await this.prisma.product.findUnique({
        where: { id },
        include: PRODUCT_DETAIL_INCLUDE,
      });
      if (product && (product.status === ProductStatus.DELETED || product.deletedAt !== null)) {
        return null;
      }
      return product;
    }, 'Erro ao buscar produto');
  }

  async findBySellerId(sellerId: string) {
    return repositoryResponse(async () => {
      const products = await this.prisma.product.findMany({
        where: { sellerId, status: ProductStatus.ACTIVE, deletedAt: null },
        orderBy: { createdAt: 'desc' },
        include: PRODUCT_LIST_INCLUDE,
      });
      return products;
    }, 'Erro ao buscar produtos do vendedor');
  }

  async findMany(params: FindManyParams) {
    return repositoryResponse(async () => {
      const { cursor, limit = DEFAULT_PAGE_SIZE, search, categoryId, minPrice, maxPrice, condition, sort = ProductSort.RECENT } = params;
      const where: Prisma.ProductWhereInput = { status: ProductStatus.ACTIVE, deletedAt: null };
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
      if (minPrice !== undefined || maxPrice !== undefined) {
        const priceFilter: Prisma.IntFilter = {};
        if (minPrice !== undefined) priceFilter.gte = minPrice;
        if (maxPrice !== undefined) priceFilter.lte = maxPrice;
        where.price = priceFilter;
      }

      const products = await this.prisma.product.findMany({
        where,
        orderBy: this.buildOrderBy(sort),
        take: limit,
        ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
        include: PRODUCT_LIST_INCLUDE,
      });
      return products;
    }, 'Erro ao listar produtos');
  }

  private buildOrderBy(sort: ProductSort): Prisma.ProductOrderByWithRelationInput[] {
    switch (sort) {
      case ProductSort.PRICE_ASC:
        return [{ price: 'asc' }, { id: 'asc' }];
      case ProductSort.PRICE_DESC:
        return [{ price: 'desc' }, { id: 'asc' }];
      case ProductSort.POPULAR:
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
    let queueIndex = 0;

    while (queueIndex < queue.length) {
      const curr = queue[queueIndex++];
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
    return repositoryResponse(async () => {
      const product = await this.prisma.product.create({ data, include: PRODUCT_DETAIL_INCLUDE });
      return product;
    }, 'Erro ao criar produto');
  }

  async update(id: string, data: Prisma.ProductUpdateInput) {
    return repositoryResponse(async () => {
      const product = await this.prisma.product.update({
        where: { id },
        data,
        include: PRODUCT_DETAIL_INCLUDE,
      });
      return product;
    }, 'Erro ao atualizar produto');
  }

  async delete(id: string) {
    return repositoryResponse(async () => {
      await this.prisma.product.update({
        where: { id },
        data: { status: ProductStatus.DELETED, deletedAt: new Date() },
      });
    }, 'Erro ao remover produto');
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
        where: { id: productId, status: { not: ProductStatus.SOLD } },
        data: { status: ProductStatus.SOLD },
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
          where: { id: productId, status: ProductStatus.SOLD },
          data: { status: ProductStatus.ACTIVE },
        });
      } else {
        await client.product.updateMany({
          where: { id: productId, status: ProductStatus.PAUSED },
          data: { status: ProductStatus.ACTIVE },
        });
      }
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to restore inventory on expiry'));
    }
  }
}
