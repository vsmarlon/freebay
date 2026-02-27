import { IOrderRepository } from '@/domain/repositories';
import { OrderEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';

export class PrismaOrderRepository implements IOrderRepository {
  async findById(id: string): Promise<OrderEntity | null> {
    return prisma.order.findUnique({ where: { id } });
  }

  async findByBuyerId(buyerId: string): Promise<OrderEntity[]> {
    return prisma.order.findMany({
      where: { buyerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findBySellerId(sellerId: string): Promise<OrderEntity[]> {
    return prisma.order.findMany({
      where: { sellerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: Omit<OrderEntity, 'id' | 'createdAt' | 'updatedAt'>): Promise<OrderEntity> {
    return prisma.order.create({ data });
  }

  async update(id: string, data: Partial<OrderEntity>): Promise<OrderEntity> {
    return prisma.order.update({ where: { id }, data });
  }
}
