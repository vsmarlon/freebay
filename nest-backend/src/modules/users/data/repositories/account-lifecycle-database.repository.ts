import { Injectable } from '@nestjs/common';
import { OrderStatus, DisputeStatus, Prisma } from '@prisma/client';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import {
  AccountDeletionBlockers,
  PurgeCandidate,
  UserDataExport,
} from '../../types/account.types';

const OPEN_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
  OrderStatus.SHIPPED,
  OrderStatus.DELIVERED,
  OrderStatus.DISPUTED,
];

const OPEN_DISPUTE_STATUSES: DisputeStatus[] = [
  DisputeStatus.OPEN,
  DisputeStatus.AWAITING_SELLER,
  DisputeStatus.AWAITING_BUYER,
];

@Injectable()
export class AccountLifecycleDatabaseRepository
  extends BasePrismaRepository
{
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findDeletionBlockers(userId: string): RepositoryResponse<AccountDeletionBlockers> {
    return this.safeRun(async () => {
      const [openOrdersAsBuyer, openOrdersAsSeller, openDisputes, wallet] = await Promise.all([
        this.prisma.order.count({
          where: { buyerId: userId, status: { in: OPEN_ORDER_STATUSES } },
        }),
        this.prisma.order.count({
          where: { sellerId: userId, status: { in: OPEN_ORDER_STATUSES } },
        }),
        this.prisma.dispute.count({
          where: {
            status: { in: OPEN_DISPUTE_STATUSES },
            order: { OR: [{ buyerId: userId }, { sellerId: userId }] },
          },
        }),
        this.prisma.wallet.findUnique({
          where: { userId },
          select: { availableBalance: true, pendingBalance: true },
        }),
      ]);

      return {
        openOrdersAsBuyer,
        openOrdersAsSeller,
        openDisputes,
        walletBalance: (wallet?.availableBalance ?? 0) + (wallet?.pendingBalance ?? 0),
      };
    }, 'Erro ao verificar pendências da conta');
  }

  async requestDeletion(userId: string, requestedAt: Date): RepositoryResponse<Date> {
    return this.safeRun(async () => {
      await this.prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id: userId },
          data: { deletionRequestedAt: requestedAt, fcmToken: null },
        });
        await tx.product.updateMany({
          where: { sellerId: userId, status: 'ACTIVE' },
          data: { status: 'PAUSED' },
        });
      });

      return requestedAt;
    }, 'Erro ao solicitar exclusão da conta');
  }

  async cancelDeletion(userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.user.update({
        where: { id: userId },
        data: { deletionRequestedAt: null },
      });
    }, 'Erro ao cancelar exclusão da conta');
  }

  async findPurgeCandidates(purgeBefore: Date): RepositoryResponse<PurgeCandidate[]> {
    return this.safeRun(
      () =>
        this.prisma.user.findMany({
          where: { deletionRequestedAt: { lte: purgeBefore }, deletedAt: null },
          select: { id: true, avatarUrl: true, bannerUrl: true },
        }),
      'Erro ao buscar contas para exclusão',
    );
  }

  async purge(userId: string, purgedAt: Date): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.user.updateMany({
          where: { id: userId, deletedAt: null, deletionRequestedAt: { not: null } },
          data: {
            deletedAt: purgedAt,
            deletionRequestedAt: null,
            email: `deleted-${userId}@deleted.invalid`,
            username: `deleted_${userId.replace(/-/g, '').slice(0, 16)}`,
            displayName: 'Usuário removido',
            emailVerified: false,
            phoneVerified: false,
            isVerified: false,
            passwordHash: null,
            googleId: null,
            cpf: null,
            cpfHash: null,
            phone: null,
            city: null,
            state: null,
            avatarUrl: null,
            bannerUrl: null,
            bio: null,
            fcmToken: null,
            notificationPrefs: Prisma.DbNull,
          },
        });

        if (claimed.count === 0) return;

        await tx.notification.deleteMany({ where: { userId } });
        await tx.savedPost.deleteMany({ where: { userId } });
        await tx.favorite.deleteMany({ where: { userId } });
        await tx.cartItem.deleteMany({ where: { userId } });
        await tx.follow.deleteMany({
          where: { OR: [{ followerId: userId }, { followingId: userId }] },
        });
        await tx.block.deleteMany({
          where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
        });
        await tx.like.deleteMany({ where: { userId } });
        await tx.share.deleteMany({ where: { userId } });
        await tx.commentLike.deleteMany({ where: { userId } });
        await tx.phoneVerificationCode.deleteMany({ where: { userId } });
        await tx.story.updateMany({
          where: { userId, deletedAt: null },
          data: { deletedAt: purgedAt },
        });
        await tx.post.updateMany({
          where: { userId, deletedAt: null },
          data: { deletedAt: purgedAt },
        });
        await tx.product.updateMany({
          where: { sellerId: userId, deletedAt: null },
          data: { deletedAt: purgedAt, status: 'PAUSED' },
        });
      });
    }, 'Erro ao excluir dados da conta');
  }

  async exportData(userId: string): RepositoryResponse<UserDataExport | null> {
    return this.safeRun(async () => {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          displayName: true,
          username: true,
          email: true,
          emailVerified: true,
          cpf: true,
          phone: true,
          phoneVerified: true,
          city: true,
          state: true,
          avatarUrl: true,
          bannerUrl: true,
          bio: true,
          isVerified: true,
          role: true,
          reputationScore: true,
          totalReviews: true,
          notificationPrefs: true,
          createdAt: true,
          updatedAt: true,
          lastSeenAt: true,
          deletionRequestedAt: true,
        },
      });

      if (!user) return null;

      const [
        products,
        posts,
        comments,
        ordersAsBuyer,
        ordersAsSeller,
        transactions,
        walletEntries,
        wallet,
        connectAccount,
        reviewsGiven,
        reviewsReceived,
        directMessages,
        chatMessages,
        notifications,
        submittedReports,
        disputes,
        following,
        followers,
        blocked,
      ] = await Promise.all([
        this.prisma.product.findMany({ where: { sellerId: userId } }),
        this.prisma.post.findMany({ where: { userId } }),
        this.prisma.comment.findMany({ where: { userId } }),
        this.prisma.order.findMany({ where: { buyerId: userId } }),
        this.prisma.order.findMany({ where: { sellerId: userId } }),
        this.prisma.transaction.findMany({
          where: { order: { OR: [{ buyerId: userId }, { sellerId: userId }] } },
        }),
        this.prisma.walletEntry.findMany({ where: { userId } }),
        this.prisma.wallet.findUnique({ where: { userId } }),
        this.prisma.connectAccount.findUnique({
          where: { userId },
          select: {
            country: true,
            defaultCurrency: true,
            transfersEnabled: true,
            payoutsEnabled: true,
            detailsSubmitted: true,
            createdAt: true,
          },
        }),
        this.prisma.review.findMany({ where: { reviewerId: userId } }),
        this.prisma.review.findMany({ where: { reviewedId: userId } }),
        this.prisma.directMessage.findMany({ where: { senderId: userId } }),
        this.prisma.chatMessage.findMany({ where: { senderId: userId } }),
        this.prisma.notification.findMany({ where: { userId } }),
        this.prisma.report.findMany({ where: { reporterId: userId } }),
        this.prisma.dispute.findMany({ where: { openedById: userId } }),
        this.prisma.follow.findMany({ where: { followerId: userId }, select: { followingId: true, createdAt: true } }),
        this.prisma.follow.findMany({ where: { followingId: userId }, select: { followerId: true, createdAt: true } }),
        this.prisma.block.findMany({ where: { blockerId: userId }, select: { blockedId: true, createdAt: true } }),
      ]);

      return {
        exportedAt: new Date().toISOString(),
        profile: user,
        products,
        posts,
        comments,
        orders: { asBuyer: ordersAsBuyer, asSeller: ordersAsSeller },
        transactions,
        wallet: { balances: wallet, entries: walletEntries },
        connectAccount,
        reviews: { given: reviewsGiven, received: reviewsReceived },
        messages: { direct: directMessages, orderChat: chatMessages },
        notifications,
        submittedReports,
        disputes,
        social: { following, followers, blocked },
      };
    }, 'Erro ao exportar dados da conta');
  }
}
