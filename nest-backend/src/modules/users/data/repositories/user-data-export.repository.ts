import { Prisma } from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { UserDataExport } from '../../types/account.types';

const USER_PROFILE_SELECT = {
  id: true, displayName: true, username: true, email: true, emailVerified: true,
  cpf: true, phone: true, phoneVerified: true, city: true, state: true,
  avatarUrl: true, bannerUrl: true, bio: true, isVerified: true, role: true,
  reputationScore: true, totalReviews: true, notificationPrefs: true,
  createdAt: true, updatedAt: true, lastSeenAt: true, deletionRequestedAt: true,
} satisfies Prisma.UserSelect;

type UserProfile = Prisma.UserGetPayload<{ select: typeof USER_PROFILE_SELECT }>;

export class UserDataExportRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async exportData(userId: string): RepositoryResponse<UserDataExport | null> {
    return repositoryResponse(async () => {
      const user: UserProfile | null = await this.prisma.user.findUnique({ where: { id: userId }, select: USER_PROFILE_SELECT });
      if (!user) return null;

      const [
        products, posts, comments, ordersAsBuyer, ordersAsSeller, transactions,
        walletEntries, wallet, connectAccount, reviewsGiven, reviewsReceived,
        directMessages, chatMessages, notifications, submittedReports, disputes,
        following, followers, blocked,
      ] = await Promise.all([
        this.prisma.product.findMany({ where: { sellerId: userId } }),
        this.prisma.post.findMany({ where: { userId } }),
        this.prisma.comment.findMany({ where: { userId } }),
        this.prisma.order.findMany({ where: { buyerId: userId } }),
        this.prisma.order.findMany({ where: { sellerId: userId } }),
        this.prisma.transaction.findMany({ where: { order: { OR: [{ buyerId: userId }, { sellerId: userId }] } } }),
        this.prisma.walletEntry.findMany({ where: { userId } }),
        this.prisma.wallet.findUnique({ where: { userId } }),
        this.prisma.connectAccount.findUnique({ where: { userId }, select: { country: true, defaultCurrency: true, transfersEnabled: true, payoutsEnabled: true, detailsSubmitted: true, createdAt: true } }),
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
        exportedAt: new Date().toISOString(), profile: user, products, posts, comments,
        orders: { asBuyer: ordersAsBuyer, asSeller: ordersAsSeller }, transactions,
        wallet: { balances: wallet, entries: walletEntries }, connectAccount,
        reviews: { given: reviewsGiven, received: reviewsReceived },
        messages: { direct: directMessages, orderChat: chatMessages }, notifications,
        submittedReports, disputes, social: { following, followers, blocked },
      };
    }, 'Erro ao exportar dados da conta');
  }
}
