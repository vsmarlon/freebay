import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class PrismaWalletRepository {
  constructor(private prisma: PrismaService) {}

  async findByUserId(userId: string) {
    return this.prisma.wallet.findUnique({
      where: { userId },
      include: { user: { select: { id: true, displayName: true } } },
    });
  }

  async getTransactions(userId: string) {
    const ordersAsBuyer = await this.prisma.order.findMany({
      where: { buyerId: userId },
      select: { id: true, amount: true, status: true, createdAt: true, sellerId: true },
    });

    const ordersAsSeller = await this.prisma.order.findMany({
      where: { sellerId: userId },
      select: { id: true, amount: true, status: true, createdAt: true, sellerAmount: true },
    });

    const buyerTx = ordersAsBuyer.map(o => ({
      id: o.id,
      orderId: o.id,
      amount: o.amount,
      status: o.status,
      createdAt: o.createdAt,
      type: 'PURCHASE' as const,
    }));

    const sellerTx = ordersAsSeller.map(o => ({
      id: o.id + '-sale',
      orderId: o.id,
      amount: o.sellerAmount ?? 0,
      status: o.status,
      createdAt: o.createdAt,
      type: 'SALE' as const,
    }));

    return [...buyerTx, ...sellerTx];
  }
}
