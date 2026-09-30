import { Injectable } from '@nestjs/common';
import { OrderStatus, DisputeStatus, Prisma } from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { AccountDeletionBlockers, PurgeCandidate, UserDataExport } from '../../types/account.types';
import { UserDataExportRepository } from './user-data-export.repository';

const OPEN_ORDER_STATUSES: OrderStatus[] = [OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.DISPUTED];
const OPEN_DISPUTE_STATUSES: DisputeStatus[] = [DisputeStatus.OPEN, DisputeStatus.AWAITING_SELLER, DisputeStatus.AWAITING_BUYER];

@Injectable()
export class AccountLifecycleDatabaseRepository {
  private readonly dataExport: UserDataExportRepository;

  constructor(private readonly prisma: PrismaService) {
    this.dataExport = new UserDataExportRepository(prisma);
  }

  async findDeletionBlockers(userId: string): RepositoryResponse<AccountDeletionBlockers> {
    return repositoryResponse(async () => {
      const [openOrdersAsBuyer, openOrdersAsSeller, openDisputes, wallet] = await Promise.all([
        this.prisma.order.count({ where: { buyerId: userId, status: { in: OPEN_ORDER_STATUSES } } }),
        this.prisma.order.count({ where: { sellerId: userId, status: { in: OPEN_ORDER_STATUSES } } }),
        this.prisma.dispute.count({ where: { status: { in: OPEN_DISPUTE_STATUSES }, order: { OR: [{ buyerId: userId }, { sellerId: userId }] } } }),
        this.prisma.wallet.findUnique({ where: { userId }, select: { availableBalance: true, pendingBalance: true } }),
      ]);
      return { openOrdersAsBuyer, openOrdersAsSeller, openDisputes, walletBalance: (wallet?.availableBalance ?? 0) + (wallet?.pendingBalance ?? 0) };
    }, 'Erro ao verificar pendências da conta');
  }

  async requestDeletion(userId: string, requestedAt: Date): RepositoryResponse<Date> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        await tx.user.update({ where: { id: userId }, data: { deletionRequestedAt: requestedAt, fcmToken: null } });
        await tx.pushDevice.deleteMany({ where: { userId } });
        await tx.product.updateMany({ where: { sellerId: userId, status: 'ACTIVE' }, data: { status: 'PAUSED' } });
      });
      return requestedAt;
    }, 'Erro ao solicitar exclusão da conta');
  }

  async cancelDeletion(userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.user.update({ where: { id: userId }, data: { deletionRequestedAt: null } });
    }, 'Erro ao cancelar exclusão da conta');
  }

  async findPurgeCandidates(purgeBefore: Date): RepositoryResponse<PurgeCandidate[]> {
    return repositoryResponse(() => this.prisma.user.findMany({ where: { deletionRequestedAt: { lte: purgeBefore }, deletedAt: null }, select: { id: true, avatarUrl: true, bannerUrl: true } }), 'Erro ao buscar contas para exclusão');
  }

  async purge(userId: string, purgedAt: Date): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.user.updateMany({ where: { id: userId, deletedAt: null, deletionRequestedAt: { not: null } }, data: {
          deletedAt: purgedAt, deletionRequestedAt: null, email: `deleted-${userId}@deleted.invalid`, username: `deleted_${userId.replace(/-/g, '').slice(0, 16)}`,
          displayName: 'Usuário removido', emailVerified: false, phoneVerified: false, isVerified: false, passwordHash: null, googleId: null,
          cpf: null, cpfHash: null, phone: null, city: null, state: null, avatarUrl: null, bannerUrl: null, bio: null, fcmToken: null, notificationPrefs: Prisma.DbNull,
        } });
        if (claimed.count === 0) return;
        await tx.pushDevice.deleteMany({ where: { userId } });
        await tx.notification.deleteMany({ where: { userId } });
        await tx.savedPost.deleteMany({ where: { userId } });
        await tx.favorite.deleteMany({ where: { userId } });
        await tx.cartItem.deleteMany({ where: { userId } });
        await tx.follow.deleteMany({ where: { OR: [{ followerId: userId }, { followingId: userId }] } });
        await tx.block.deleteMany({ where: { OR: [{ blockerId: userId }, { blockedId: userId }] } });
        await tx.like.deleteMany({ where: { userId } });
        await tx.share.deleteMany({ where: { userId } });
        await tx.commentLike.deleteMany({ where: { userId } });
        await tx.phoneVerificationCode.deleteMany({ where: { userId } });
        await tx.story.updateMany({ where: { userId, deletedAt: null }, data: { deletedAt: purgedAt } });
        await tx.post.updateMany({ where: { userId, deletedAt: null }, data: { deletedAt: purgedAt } });
        await tx.product.updateMany({ where: { sellerId: userId, deletedAt: null }, data: { deletedAt: purgedAt, status: 'PAUSED' } });
      });
    }, 'Erro ao excluir dados da conta');
  }

  exportData(userId: string): RepositoryResponse<UserDataExport | null> { return this.dataExport.exportData(userId); }
}
