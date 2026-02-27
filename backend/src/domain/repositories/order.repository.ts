import { OrderEntity } from '../entities';

export interface IOrderRepository {
  findById(id: string): Promise<OrderEntity | null>;
  findByBuyerId(buyerId: string): Promise<OrderEntity[]>;
  findBySellerId(sellerId: string): Promise<OrderEntity[]>;
  create(data: Omit<OrderEntity, 'id' | 'createdAt' | 'updatedAt'>): Promise<OrderEntity>;
  update(id: string, data: Partial<OrderEntity>): Promise<OrderEntity>;
}
