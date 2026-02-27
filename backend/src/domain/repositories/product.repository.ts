import { ProductEntity } from '../entities';

export interface IProductRepository {
  findById(id: string): Promise<ProductEntity | null>;
  findBySellerId(sellerId: string): Promise<ProductEntity[]>;
  findAll(params: { cursor?: string; limit?: number }): Promise<ProductEntity[]>;
  create(
    data: Omit<ProductEntity, 'id' | 'createdAt' | 'updatedAt' | 'deletedAt'>,
  ): Promise<ProductEntity>;
  update(id: string, data: Partial<ProductEntity>): Promise<ProductEntity>;
  softDelete(id: string): Promise<void>;
}
