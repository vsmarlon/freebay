import { Injectable } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaOrderRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string) {
    return this.prisma.order.findUnique({
      where: { id },
      include: {
        product: { include: { images: true } },
        buyer: { select: { id: true, displayName: true, avatarUrl: true } },
        seller: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async findByBuyerId(buyerId: string) {
    return this.prisma.order.findMany({
      where: { buyerId },
      orderBy: { createdAt: 'desc' },
      include: { product: { include: { images: true } } },
    });
  }

  async findBySellerId(sellerId: string) {
    return this.prisma.order.findMany({
      where: { sellerId },
      orderBy: { createdAt: 'desc' },
      include: { product: { include: { images: true } } },
    });
  }

  async countBySellerId(sellerId: string) {
    return this.prisma.order.count({ where: { sellerId } });
  }

  async countByBuyerId(buyerId: string) {
    return this.prisma.order.count({ where: { buyerId } });
  }

  async create(data: Prisma.OrderCreateInput) {
    return this.prisma.order.create({ data });
  }

  async update(id: string, data: Prisma.OrderUpdateInput) {
    return this.prisma.order.update({ where: { id }, data });
  }
}
