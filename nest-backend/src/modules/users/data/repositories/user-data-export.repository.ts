import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { UserDataExport } from '../../types/account.types';

const USER_PROFILE_SELECT = {
  id: true, displayName: true, username: true, email: true, emailVerified: true,
  cpf: true, phone: true, phoneVerified: true, city: true, state: true,
  avatarUrl: true, avatarBlurHash: true, bannerUrl: true, bio: true, isVerified: true, role: true,
  reputationScore: true, totalReviews: true, notificationPrefs: true,
  webConsentGrantedAt: true, webConsentIp: true, webConsentUserAgent: true,
  createdAt: true, updatedAt: true, lastSeenAt: true, deletionRequestedAt: true,
} satisfies Prisma.UserSelect;

const PRODUCT_SELECT = {
  id: true, title: true, description: true, price: true, condition: true, categoryId: true,
  status: true, quantity: true, soldCount: true, postId: true, createdAt: true, updatedAt: true, deletedAt: true,
  images: { select: { id: true, url: true, blurHash: true, order: true } },
} satisfies Prisma.ProductSelect;

const POST_SELECT = {
  id: true, content: true, imageUrl: true, imageBlurHash: true, type: true, audience: true,
  likesCount: true, commentsCount: true, sharesCount: true, createdAt: true, updatedAt: true, deletedAt: true,
} satisfies Prisma.PostSelect;

const COMMENT_SELECT = {
  id: true, content: true, postId: true, parentId: true, likesCount: true, createdAt: true, deletedAt: true,
} satisfies Prisma.CommentSelect;

const ORDER_SELECT = {
  id: true, productId: true, quantity: true, amount: true, platformFee: true, sellerAmount: true,
  status: true, escrowStatus: true, meetingScheduledAt: true, deliveryConfirmedAt: true,
  cancellationReason: true, createdAt: true, updatedAt: true,
} satisfies Prisma.OrderSelect;

const TRANSACTION_SELECT = {
  id: true, orderId: true, amount: true, platformFee: true, sellerAmount: true, paymentMethod: true,
  status: true, paidAt: true, releasedAt: true, createdAt: true, updatedAt: true,
} satisfies Prisma.TransactionSelect;

const WALLET_ENTRY_SELECT = {
  id: true, kind: true, amount: true, reason: true, orderId: true, createdAt: true,
} satisfies Prisma.WalletEntrySelect;

const WALLET_SELECT = { availableBalance: true, pendingBalance: true, totalEarned: true } satisfies Prisma.WalletSelect;

const CONNECT_ACCOUNT_SELECT = {
  country: true, defaultCurrency: true, transfersEnabled: true, payoutsEnabled: true,
  detailsSubmitted: true, createdAt: true,
} satisfies Prisma.ConnectAccountSelect;

const REVIEW_SELECT = {
  id: true, orderId: true, type: true, score: true, comment: true, createdAt: true,
  images: { select: { id: true, url: true, order: true } },
} satisfies Prisma.ReviewSelect;
const RECEIVED_REVIEW_SELECT = {
  id: true, orderId: true, type: true, score: true, createdAt: true,
  images: { select: { id: true, url: true, order: true } },
} satisfies Prisma.ReviewSelect;

const DIRECT_MESSAGE_SELECT = {
  id: true, conversationId: true, content: true, type: true, attachmentUrl: true,
  viewOnce: true, deletedAt: true, createdAt: true,
} satisfies Prisma.DirectMessageSelect;

const CHAT_MESSAGE_SELECT = {
  id: true, orderId: true, content: true, type: true, attachmentUrl: true,
  viewOnce: true, deletedAt: true, createdAt: true,
} satisfies Prisma.ChatMessageSelect;

const NOTIFICATION_SELECT = {
  id: true, type: true, title: true, body: true, read: true, createdAt: true,
} satisfies Prisma.NotificationSelect;

const SUBMITTED_REPORT_SELECT = {
  id: true, reportedUserId: true, reportedPostId: true, targetType: true,
  reportedDirectConversationId: true, reportedOrderChatId: true,
  reportedDirectMessageId: true, reportedChatMessageId: true, reason: true,
  createdAt: true,
} satisfies Prisma.ReportSelect;

const DISPUTE_SELECT = { id: true, orderId: true, createdAt: true, expiresAt: true } satisfies Prisma.DisputeSelect;
const STORY_SELECT = {
  id: true, imageUrl: true, mediaType: true, audience: true, caption: true, textBlocks: true,
  expiresAt: true, createdAt: true, deletedAt: true,
} satisfies Prisma.StorySelect;
const SAVED_POST_SELECT = { id: true, postId: true, createdAt: true } satisfies Prisma.SavedPostSelect;
const LIKE_SELECT = { id: true, postId: true, createdAt: true } satisfies Prisma.LikeSelect;
const SHARE_SELECT = { id: true, postId: true, createdAt: true } satisfies Prisma.ShareSelect;
const FAVORITE_SELECT = { id: true, productId: true, createdAt: true } satisfies Prisma.FavoriteSelect;
const CART_SELECT = { id: true, productId: true, quantity: true, createdAt: true, updatedAt: true } satisfies Prisma.CartItemSelect;

const EXPORT_SCOPE = {
  included: [
    'profile and consent metadata', 'owned products with image URLs, authored posts/comments/stories',
    'orders in either role, related transactions, wallet balances/entries, and limited Connect status',
    'reviews given/received with selected image URLs, authored direct/order-chat messages, notifications',
    'submitted report categories, order-related dispute dates, saved posts, likes, shares, favorites, cart, follows, followers, and blocks in both directions',
  ],
  excluded: [
    'password, session, OTP, provider identity and encrypted provider credentials',
    'other users’ email, phone, CPF, profile or contact details',
    'payment-provider identifiers, idempotency secrets, transfer internals and raw provider payloads',
    'moderation decisions, free-text report/dispute details, reviewer identities, private dispute evidence, notification payloads and other-party message read receipts',
    'media file bytes, server/access logs, comment likes, message reactions/stars, story view/highlight/private-list records, and other model records outside the listed collections',
  ],
};

type UserProfile = Prisma.UserGetPayload<{ select: typeof USER_PROFILE_SELECT }>;

@Injectable()
export class UserDataExportRepository {
  constructor(private readonly prisma: PrismaService) {}

  async exportData(userId: string): RepositoryResponse<UserDataExport | null> {
    return repositoryResponse(async () => {
      const user: UserProfile | null = await this.prisma.user.findUnique({ where: { id: userId }, select: USER_PROFILE_SELECT });
      if (!user) return null;

      const [
        products, posts, comments, ordersAsBuyer, ordersAsSeller, transactions,
        walletEntries, wallet, connectAccount, reviewsGiven, reviewsReceived,
        directMessages, chatMessages, notifications, submittedReports, disputes,
        following, followers, blocked, stories, savedPosts, likes, shares, favorites, cart,
        blockedBy,
      ] = await Promise.all([
        this.prisma.product.findMany({ where: { sellerId: userId }, select: PRODUCT_SELECT }),
        this.prisma.post.findMany({ where: { userId }, select: POST_SELECT }),
        this.prisma.comment.findMany({ where: { userId }, select: COMMENT_SELECT }),
        this.prisma.order.findMany({ where: { buyerId: userId }, select: ORDER_SELECT }),
        this.prisma.order.findMany({ where: { sellerId: userId }, select: ORDER_SELECT }),
        this.prisma.transaction.findMany({ where: { order: { OR: [{ buyerId: userId }, { sellerId: userId }] } }, select: TRANSACTION_SELECT }),
        this.prisma.walletEntry.findMany({ where: { userId }, select: WALLET_ENTRY_SELECT }),
        this.prisma.wallet.findUnique({ where: { userId }, select: WALLET_SELECT }),
        this.prisma.connectAccount.findUnique({ where: { userId }, select: CONNECT_ACCOUNT_SELECT }),
        this.prisma.review.findMany({ where: { reviewerId: userId }, select: REVIEW_SELECT }),
        this.prisma.review.findMany({ where: { reviewedId: userId }, select: RECEIVED_REVIEW_SELECT }),
        this.prisma.directMessage.findMany({ where: { senderId: userId }, select: DIRECT_MESSAGE_SELECT }),
        this.prisma.chatMessage.findMany({ where: { senderId: userId }, select: CHAT_MESSAGE_SELECT }),
        this.prisma.notification.findMany({ where: { userId }, select: NOTIFICATION_SELECT }),
        this.prisma.report.findMany({ where: { reporterId: userId }, select: SUBMITTED_REPORT_SELECT }),
        this.prisma.dispute.findMany({ where: { order: { OR: [{ buyerId: userId }, { sellerId: userId }] } }, select: DISPUTE_SELECT }),
        this.prisma.follow.findMany({ where: { followerId: userId }, select: { followingId: true, createdAt: true } }),
        this.prisma.follow.findMany({ where: { followingId: userId }, select: { followerId: true, createdAt: true } }),
        this.prisma.block.findMany({ where: { blockerId: userId }, select: { blockedId: true, createdAt: true } }),
        this.prisma.story.findMany({ where: { userId }, select: STORY_SELECT }),
        this.prisma.savedPost.findMany({ where: { userId }, select: SAVED_POST_SELECT }),
        this.prisma.like.findMany({ where: { userId }, select: LIKE_SELECT }),
        this.prisma.share.findMany({ where: { userId }, select: SHARE_SELECT }),
        this.prisma.favorite.findMany({ where: { userId }, select: FAVORITE_SELECT }),
        this.prisma.cartItem.findMany({ where: { userId }, select: CART_SELECT }),
        this.prisma.block.findMany({ where: { blockedId: userId }, select: { blockerId: true, createdAt: true } }),
      ]);

      return {
        exportedAt: new Date().toISOString(), scope: EXPORT_SCOPE, profile: user, products, posts, comments,
        orders: { asBuyer: ordersAsBuyer, asSeller: ordersAsSeller }, transactions,
        wallet: { balances: wallet, entries: walletEntries }, connectAccount,
        reviews: { given: reviewsGiven, received: reviewsReceived },
        messages: { direct: directMessages, orderChat: chatMessages }, notifications,
        submittedReports, disputes, stories, savedPosts, likes, shares, favorites, cart,
        social: { following, followers, blocked, blockedBy },
      };
    }, 'Erro ao exportar dados da conta');
  }
}
