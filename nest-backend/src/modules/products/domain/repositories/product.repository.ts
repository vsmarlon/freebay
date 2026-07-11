import { Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { ProductDetailPayload, ProductListPayload, FindManyParams } from '../../types/product.types';

export abstract class ProductRepository {
  abstract findById(id: string): RepositoryResponse<ProductDetailPayload | null>;
  abstract findBySellerId(sellerId: string): RepositoryResponse<ProductListPayload[]>;
  abstract findMany(params: FindManyParams): RepositoryResponse<ProductListPayload[]>;
  abstract create(data: Prisma.ProductCreateInput): RepositoryResponse<ProductDetailPayload>;
  abstract update(id: string, data: Prisma.ProductUpdateInput): RepositoryResponse<ProductDetailPayload>;
  abstract delete(id: string): RepositoryResponse<void>;
  abstract updateInventoryOnSale(productId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
  abstract restoreInventoryOnExpiry(productId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
}
