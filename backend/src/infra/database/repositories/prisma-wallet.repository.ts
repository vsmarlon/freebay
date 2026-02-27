import { IWalletRepository } from '@/domain/repositories';
import { WalletEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';

export class PrismaWalletRepository implements IWalletRepository {
  async findByUserId(userId: string): Promise<WalletEntity | null> {
    return prisma.wallet.findUnique({ where: { userId } });
  }

  async create(userId: string): Promise<WalletEntity> {
    return prisma.wallet.create({
      data: {
        userId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
      },
    });
  }

  async updateBalance(
    userId: string,
    data: Partial<Pick<WalletEntity, 'availableBalance' | 'pendingBalance' | 'totalEarned'>>,
  ): Promise<WalletEntity> {
    return prisma.wallet.update({
      where: { userId },
      data,
    });
  }

  async setRecipientId(userId: string, recipientId: string): Promise<WalletEntity> {
    return prisma.wallet.update({
      where: { userId },
      data: { recipientId },
    });
  }
}
