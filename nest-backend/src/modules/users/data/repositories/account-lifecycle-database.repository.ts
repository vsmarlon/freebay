import { Injectable } from '@nestjs/common';
import { OrderStatus, DisputeStatus, Prisma } from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { AccountDeletionBlockers, PersonalPurgeStatus, PurgeCandidate, UserDataExport } from '../../types/account.types';
import { UserDataExportRepository } from './user-data-export.repository';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

const OPEN_ORDER_STATUSES: OrderStatus[] = [OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.SHIPPED, OrderStatus.DELIVERED, OrderStatus.DISPUTED];
const OPEN_DISPUTE_STATUSES: DisputeStatus[] = [DisputeStatus.OPEN, DisputeStatus.AWAITING_SELLER, DisputeStatus.AWAITING_BUYER];

@Injectable()
export class AccountLifecycleDatabaseRepository {
  private readonly dataExport: UserDataExportRepository;

  constructor(
    private readonly prisma: PrismaService,
    private readonly authSessionState: AuthSessionStateDatabaseRepository,
  ) {
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
        await this.authSessionState.advanceInvalidBeforeInTransaction(tx, userId, requestedAt);
        await tx.pushDevice.deleteMany({ where: { userId } });
        await tx.product.updateMany({ where: { sellerId: userId, status: 'ACTIVE' }, data: { status: 'PAUSED' } });
      });
      return requestedAt;
    }, 'Erro ao solicitar exclusão da conta');
  }

  async cancelDeletion(userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.findUnique({
          where: { id: userId },
          select: { deletionRequestedAt: true, sessionsInvalidBefore: true },
        });
        if (user?.sessionsInvalidBefore === null && user.deletionRequestedAt) {
          await this.authSessionState.advanceInvalidBeforeInTransaction(tx, userId, user.deletionRequestedAt);
        }
        await tx.user.update({ where: { id: userId }, data: { deletionRequestedAt: null } });
      });
    }, 'Erro ao cancelar exclusão da conta');
  }

  async findPurgeCandidates(purgeBefore: Date): RepositoryResponse<PurgeCandidate[]> {
    return repositoryResponse(() => this.prisma.user.findMany({
      where: {
        OR: [
          { deletionRequestedAt: { lte: purgeBefore }, deletedAt: null },
          { deletedAt: { not: null }, personalPurgeCompletedAt: null },
        ],
      },
      select: { id: true },
    }), 'Erro ao buscar contas para exclusão');
  }

  async purge(userId: string, purgeBefore: Date, purgedAt: Date): RepositoryResponse<PersonalPurgeStatus> {
    return repositoryResponse(async () => {
      return this.prisma.$transaction(async (tx): Promise<PersonalPurgeStatus> => {
        const user = await tx.user.findUnique({
          where: { id: userId },
          select: {
            deletionRequestedAt: true,
            deletedAt: true,
            personalPurgePendingMedia: true,
            personalPurgeCompletedAt: true,
            email: true,
            avatarUrl: true,
            bannerUrl: true,
          },
        });
        if (!user) return 'canceled';
        if (user.deletedAt) {
          if (user.personalPurgeCompletedAt) return 'completed';
          if (user.personalPurgePendingMedia.length) return 'pending-media';
          if (await this.hasPersonalRetentionGate(tx, userId)) return 'pending-review';
          return 'pending-verification';
        }
        if (!user.deletionRequestedAt || user.deletionRequestedAt > purgeBefore) return 'canceled';

        const [posts, stories, directMessages, chatMessages, preferences, unlinkedProductIds] = await Promise.all([
          tx.post.findMany({ where: { userId, imageUrl: { not: null } }, select: { imageUrl: true } }),
          tx.story.findMany({ where: { userId }, select: { imageUrl: true } }),
          tx.directMessage.findMany({ where: { senderId: userId, attachmentUrl: { not: null } }, select: { attachmentUrl: true } }),
          tx.chatMessage.findMany({ where: { senderId: userId, attachmentUrl: { not: null } }, select: { attachmentUrl: true } }),
          tx.conversationPreference.findMany({ where: { userId, backgroundUrl: { not: null } }, select: { backgroundUrl: true } }),
          tx.product.findMany({ where: { sellerId: userId, deletedAt: null, orders: { none: {} } }, select: { id: true } }),
        ]);
        const unlinkedProducts: Array<{ id: string; images: Array<{ url: string }>; hasPreservedReference: boolean }> = [];
        let hasUnresolvedProductReference = false;
        for (const { id } of unlinkedProductIds) {
          await tx.$queryRaw(Prisma.sql`SELECT "id" FROM "Product" WHERE "id" = ${id} FOR UPDATE`);
          let product = await tx.product.findUnique({
            where: { id },
            select: {
              sellerId: true,
              deletedAt: true,
              orders: { take: 1, select: { id: true } },
              images: { select: { url: true } },
              directConversations: { take: 1, select: { id: true } },
              favorites: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
              cartItems: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
              post: { select: {
                id: true,
                comments: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                likes: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                shares: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                savedBy: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                reportedPostReports: { take: 1, select: { id: true } },
              } },
            },
          });
          if (!product || product.sellerId !== userId || product.deletedAt || product.orders.length) continue;
          if (product.post) {
            await tx.$queryRaw(Prisma.sql`SELECT "id" FROM "Post" WHERE "id" = ${product.post.id} FOR UPDATE`);
            product = await tx.product.findUnique({
              where: { id },
              select: {
                sellerId: true,
                deletedAt: true,
                orders: { take: 1, select: { id: true } },
                images: { select: { url: true } },
                directConversations: { take: 1, select: { id: true } },
                favorites: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                cartItems: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                post: { select: {
                  id: true,
                  comments: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                  likes: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                  shares: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                  savedBy: { where: { userId: { not: userId } }, take: 1, select: { id: true } },
                  reportedPostReports: { take: 1, select: { id: true } },
                } },
              },
            });
            if (!product || product.sellerId !== userId || product.deletedAt || product.orders.length) continue;
          }
          const moderationReferenceTargets: Prisma.ModerationActionWhereInput[] = [{ targetType: 'PRODUCT', targetId: id }];
          if (product.post) moderationReferenceTargets.push({ targetType: 'POST', targetId: product.post.id });
          const moderationReferences = await tx.moderationAction.count({ where: { OR: moderationReferenceTargets } });
          const hasPreservedReference = product.directConversations.length > 0
            || product.favorites.length > 0
            || product.cartItems.length > 0
            || Boolean(product.post && (
              product.post.comments.length > 0
              || product.post.likes.length > 0
              || product.post.shares.length > 0
              || product.post.savedBy.length > 0
              || product.post.reportedPostReports.length > 0
            ))
            || moderationReferences > 0;
          unlinkedProducts.push({ id, images: product.images, hasPreservedReference });
          hasUnresolvedProductReference ||= hasPreservedReference;
        }
        const pendingMedia = [...new Set([
          ...user.personalPurgePendingMedia,
          user.avatarUrl,
          user.bannerUrl,
          ...posts.map(({ imageUrl }) => imageUrl),
          ...stories.map(({ imageUrl }) => imageUrl),
          ...directMessages.map(({ attachmentUrl }) => attachmentUrl),
          ...chatMessages.map(({ attachmentUrl }) => attachmentUrl),
          ...preferences.map(({ backgroundUrl }) => backgroundUrl),
          ...unlinkedProducts.filter(({ hasPreservedReference }) => !hasPreservedReference).flatMap(({ images }) => images.map(({ url }) => url)),
        ].filter((url): url is string => Boolean(url)))];
        const reviewGate = await this.hasPersonalRetentionGate(tx, userId);

        const claimed = await tx.user.updateMany({
          where: { id: userId, deletedAt: null, deletionRequestedAt: { equals: user.deletionRequestedAt, lte: purgeBefore } },
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
            appleId: null,
            appleRefreshTokenEncrypted: null,
            cpf: null,
            cpfHash: null,
            phone: null,
            city: null,
            state: null,
            avatarUrl: null,
            avatarBlurHash: null,
            bannerUrl: null,
            bio: null,
            fcmToken: null,
            notificationPrefs: Prisma.DbNull,
            webConsentGrantedAt: null,
            webConsentIp: null,
            webConsentUserAgent: null,
            lastSeenAt: null,
            personalPurgePendingMedia: pendingMedia,
            personalPurgeCompletedAt: pendingMedia.length || reviewGate || hasUnresolvedProductReference ? null : purgedAt,
          },
        });
        if (claimed.count === 0) return 'canceled';

        await tx.pushDevice.deleteMany({ where: { userId } });
        await tx.notification.deleteMany({ where: { userId } });
        await tx.passwordRecoveryCode.deleteMany({ where: { userId } });
        await tx.webMagicLink.deleteMany({ where: { email: user.email } });
        await tx.savedPost.deleteMany({ where: { userId } });
        await tx.favorite.deleteMany({ where: { userId } });
        await tx.cartItem.deleteMany({ where: { userId } });
        await tx.conversationPreference.deleteMany({ where: { userId } });
        await tx.follow.deleteMany({ where: { OR: [{ followerId: userId }, { followingId: userId }] } });
        await tx.block.deleteMany({ where: { OR: [{ blockerId: userId }, { blockedId: userId }] } });
        await tx.closeFriend.deleteMany({ where: { OR: [{ ownerId: userId }, { memberId: userId }] } });
        await tx.restriction.deleteMany({ where: { OR: [{ ownerId: userId }, { restrictedId: userId }] } });
        const decrementPostCounter = async (postId: string, counter: 'likesCount' | 'sharesCount' | 'commentsCount', count: number) => {
          for (let index = 0; index < count; index += 1) {
            await tx.post.updateMany({ where: { id: postId, [counter]: { gt: 0 } }, data: { [counter]: { decrement: 1 } } });
          }
        };
        const decrementCommentLikes = async (commentId: string, count: number) => {
          for (let index = 0; index < count; index += 1) {
            await tx.comment.updateMany({ where: { id: commentId, deletedAt: null, likesCount: { gt: 0 } }, data: { likesCount: { decrement: 1 } } });
          }
        };

        const likedPosts = [...new Set((await tx.like.findMany({ where: { userId }, select: { postId: true } })).map(({ postId }) => postId))];
        for (const postId of likedPosts) {
          const removed = await tx.like.deleteMany({ where: { userId, postId } });
          await decrementPostCounter(postId, 'likesCount', removed.count);
        }
        const sharedPosts = [...new Set((await tx.share.findMany({ where: { userId }, select: { postId: true } })).map(({ postId }) => postId))];
        for (const postId of sharedPosts) {
          const removed = await tx.share.deleteMany({ where: { userId, postId } });
          await decrementPostCounter(postId, 'sharesCount', removed.count);
        }
        const likedComments = [...new Set((await tx.commentLike.findMany({ where: { userId, comment: { deletedAt: null } }, select: { commentId: true } })).map(({ commentId }) => commentId))];
        for (const commentId of likedComments) {
          const removed = await tx.commentLike.deleteMany({ where: { userId, commentId } });
          await decrementCommentLikes(commentId, removed.count);
        }
        await tx.commentLike.deleteMany({ where: { userId } });
        await tx.like.deleteMany({ where: { userId } });
        await tx.share.deleteMany({ where: { userId } });
        await tx.messageReaction.deleteMany({ where: { userId } });
        await tx.starredMessage.deleteMany({ where: { userId } });
        await tx.phoneVerificationCode.deleteMany({ where: { userId } });
        await tx.storyHighlight.deleteMany({ where: { userId } });
        await tx.storyView.deleteMany({ where: { viewerId: userId } });
        await tx.story.updateMany({ where: { userId, deletedAt: null }, data: { deletedAt: purgedAt, imageUrl: '', caption: null, textBlocks: Prisma.DbNull } });
        await tx.post.updateMany({ where: { userId, deletedAt: null }, data: { deletedAt: purgedAt, content: null, imageUrl: null, imageBlurHash: null } });
        const authoredComments = await tx.comment.findMany({ where: { userId, deletedAt: null }, select: { id: true } });
        for (const { id } of authoredComments) {
          await tx.$queryRaw(Prisma.sql`SELECT "id" FROM "Comment" WHERE "id" = ${id} FOR UPDATE`);
          const comment = await tx.comment.findUnique({
            where: { id },
            select: { postId: true, isHidden: true, deletedAt: true, replies: { take: 1, select: { id: true } } },
          });
          if (!comment || comment.deletedAt) continue;
          const hasReplies = comment.replies.length > 0;
          const removed = await tx.comment.updateMany({
            where: { id, deletedAt: null, isHidden: comment.isHidden },
            data: { content: '', ...(hasReplies ? {} : { deletedAt: purgedAt }) },
          });
          if (removed.count && !hasReplies && !comment.isHidden) await decrementPostCounter(comment.postId, 'commentsCount', 1);
        }
        await tx.directMessage.updateMany({ where: { senderId: userId, deletedAt: null }, data: { deletedAt: purgedAt, content: null, attachmentUrl: null, metadata: Prisma.DbNull } });
        await tx.chatMessage.updateMany({ where: { senderId: userId, deletedAt: null }, data: { deletedAt: purgedAt, content: null, attachmentUrl: null, metadata: Prisma.DbNull } });
        for (const product of unlinkedProducts) {
          const updated = await tx.product.updateMany({
            where: {
              id: product.id,
              sellerId: userId,
              deletedAt: null,
              orders: { none: {} },
              ...(product.hasPreservedReference ? {} : {
                directConversations: { none: {} },
                favorites: { none: { userId: { not: userId } } },
                cartItems: { none: { userId: { not: userId } } },
                OR: [
                  { post: null },
                  { post: { is: {
                    comments: { none: { userId: { not: userId } } },
                    likes: { none: { userId: { not: userId } } },
                    shares: { none: { userId: { not: userId } } },
                    savedBy: { none: { userId: { not: userId } } },
                    reportedPostReports: { none: {} },
                  } } },
                ],
              }),
            },
            data: { deletedAt: purgedAt, status: 'PAUSED', ...(product.hasPreservedReference ? {} : { title: 'Anúncio removido', description: '' }) },
          });
          if (updated.count === 0) {
            hasUnresolvedProductReference = true;
            continue;
          }
          if (!product.hasPreservedReference) {
            await tx.productImage.updateMany({
              where: { productId: product.id },
              data: { url: '', blurHash: null },
            });
          }
        }
        if (hasUnresolvedProductReference) {
          await tx.user.updateMany({ where: { id: userId, deletedAt: purgedAt }, data: { personalPurgeCompletedAt: null } });
        }

        if (pendingMedia.length) return 'pending-media';
        if (reviewGate) return 'pending-review';
        return hasUnresolvedProductReference ? 'pending-verification' : 'completed';
      });
    }, 'Erro ao excluir dados da conta');
  }

  private async hasPersonalRetentionGate(tx: Prisma.TransactionClient, userId: string): Promise<boolean> {
    const [reports, bugReports, posts, comments, products] = await Promise.all([
      tx.report.findMany({ where: { OR: [
        { reporterId: userId },
        { reportedUserId: userId },
        { reportedPost: { userId } },
        { reportedDirectMsg: { senderId: userId } },
        { reportedChatMsg: { senderId: userId } },
        { reportedDirectConv: { OR: [{ user1Id: userId }, { user2Id: userId }] } },
        { reportedOrder: { OR: [{ buyerId: userId }, { sellerId: userId }] } },
      ] }, select: { id: true } }),
      tx.bugReport.count({ where: { userId } }),
      tx.post.findMany({ where: { userId }, select: { id: true } }),
      tx.comment.findMany({ where: { userId }, select: { id: true } }),
      tx.product.findMany({ where: { sellerId: userId }, select: { id: true } }),
    ]);
    const moderationActions = await tx.moderationAction.count({ where: { OR: [
      { actorId: userId },
      { targetType: 'USER', targetId: userId },
      { targetType: 'POST', targetId: { in: posts.map(({ id }) => id) } },
      { targetType: 'COMMENT', targetId: { in: comments.map(({ id }) => id) } },
      { targetType: 'PRODUCT', targetId: { in: products.map(({ id }) => id) } },
      { targetType: 'REPORT', targetId: { in: reports.map(({ id }) => id) } },
    ] } });
    return reports.length > 0 || bugReports > 0 || moderationActions > 0;
  }

  exportData(userId: string): RepositoryResponse<UserDataExport | null> { return this.dataExport.exportData(userId); }
}
