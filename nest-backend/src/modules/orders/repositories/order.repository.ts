import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaOrderRepository {
  constructor(private prisma: PrismaService) {}

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

  async create(data: Prisma.OrderCreateInput) {
    return this.prisma.order.create({ data });
  }

  async update(id: string, data: Prisma.OrderUpdateInput) {
    return this.prisma.order.update({ where: { id }, data });
  }
}
