import type { CartItem, ChatMessage, Comment, ConnectAccount, DirectMessage, Dispute, Favorite, Like, Notification, Order, Post, Product, ProductImage, Report, Review, ReviewImage, SavedPost, Share, Story, Transaction, User, Wallet, WalletEntry } from '@prisma/client';

export interface AccountDeletionBlockers {
  openOrdersAsBuyer: number;
  openOrdersAsSeller: number;
  openDisputes: number;
  walletBalance: number;
}

export interface AccountDeletionState {
  deletionRequestedAt: Date | null;
  purgeAfter: Date | null;
}

export interface PurgeCandidate {
  id: string;
  avatarUrl: string | null;
  bannerUrl: string | null;
}

export interface UserDataExport {
  exportedAt: string;
  scope: { included: string[]; excluded: string[] };
  profile: Pick<User, 'id' | 'displayName' | 'username' | 'email' | 'emailVerified' | 'cpf' | 'phone' | 'phoneVerified' | 'city' | 'state' | 'avatarUrl' | 'avatarBlurHash' | 'bannerUrl' | 'bio' | 'isVerified' | 'role' | 'reputationScore' | 'totalReviews' | 'notificationPrefs' | 'webConsentGrantedAt' | 'webConsentIp' | 'webConsentUserAgent' | 'createdAt' | 'updatedAt' | 'lastSeenAt' | 'deletionRequestedAt'>;
  products: Array<Pick<Product, 'id' | 'title' | 'description' | 'price' | 'condition' | 'categoryId' | 'status' | 'quantity' | 'soldCount' | 'postId' | 'createdAt' | 'updatedAt' | 'deletedAt'> & { images: Array<Pick<ProductImage, 'id' | 'url' | 'blurHash' | 'order'>> }>;
  posts: Array<Pick<Post, 'id' | 'content' | 'imageUrl' | 'imageBlurHash' | 'type' | 'audience' | 'likesCount' | 'commentsCount' | 'sharesCount' | 'createdAt' | 'updatedAt' | 'deletedAt'>>;
  comments: Array<Pick<Comment, 'id' | 'content' | 'postId' | 'parentId' | 'likesCount' | 'createdAt' | 'deletedAt'>>;
  orders: { asBuyer: Array<Pick<Order, 'id' | 'productId' | 'quantity' | 'amount' | 'platformFee' | 'sellerAmount' | 'status' | 'escrowStatus' | 'meetingScheduledAt' | 'deliveryConfirmedAt' | 'cancellationReason' | 'createdAt' | 'updatedAt'>>; asSeller: Array<Pick<Order, 'id' | 'productId' | 'quantity' | 'amount' | 'platformFee' | 'sellerAmount' | 'status' | 'escrowStatus' | 'meetingScheduledAt' | 'deliveryConfirmedAt' | 'cancellationReason' | 'createdAt' | 'updatedAt'>> };
  transactions: Array<Pick<Transaction, 'id' | 'orderId' | 'amount' | 'platformFee' | 'sellerAmount' | 'paymentMethod' | 'status' | 'paidAt' | 'releasedAt' | 'createdAt' | 'updatedAt'>>;
  wallet: { balances: Pick<Wallet, 'availableBalance' | 'pendingBalance' | 'totalEarned'> | null; entries: Array<Pick<WalletEntry, 'id' | 'kind' | 'amount' | 'reason' | 'orderId' | 'createdAt'>> };
  connectAccount: Pick<ConnectAccount, 'country' | 'defaultCurrency' | 'transfersEnabled' | 'payoutsEnabled' | 'detailsSubmitted' | 'createdAt'> | null;
  reviews: {
    given: Array<Pick<Review, 'id' | 'orderId' | 'type' | 'score' | 'comment' | 'createdAt'> & { images: Array<Pick<ReviewImage, 'id' | 'url' | 'order'>> }>;
    received: Array<Pick<Review, 'id' | 'orderId' | 'type' | 'score' | 'createdAt'> & { images: Array<Pick<ReviewImage, 'id' | 'url' | 'order'>> }>;
  };
  messages: { direct: Array<Pick<DirectMessage, 'id' | 'conversationId' | 'content' | 'type' | 'attachmentUrl' | 'viewOnce' | 'deletedAt' | 'createdAt'>>; orderChat: Array<Pick<ChatMessage, 'id' | 'orderId' | 'content' | 'type' | 'attachmentUrl' | 'viewOnce' | 'deletedAt' | 'createdAt'>> };
  notifications: Array<Pick<Notification, 'id' | 'type' | 'title' | 'body' | 'read' | 'createdAt'>>;
  submittedReports: Array<Pick<Report, 'id' | 'reportedUserId' | 'reportedPostId' | 'targetType' | 'reportedDirectConversationId' | 'reportedOrderChatId' | 'reportedDirectMessageId' | 'reportedChatMessageId' | 'reason' | 'createdAt'>>;
  disputes: Array<Pick<Dispute, 'id' | 'orderId' | 'createdAt' | 'expiresAt'>>;
  stories: Array<Pick<Story, 'id' | 'imageUrl' | 'mediaType' | 'audience' | 'caption' | 'textBlocks' | 'expiresAt' | 'createdAt' | 'deletedAt'>>;
  savedPosts: Array<Pick<SavedPost, 'id' | 'postId' | 'createdAt'>>;
  likes: Array<Pick<Like, 'id' | 'postId' | 'createdAt'>>;
  shares: Array<Pick<Share, 'id' | 'postId' | 'createdAt'>>;
  favorites: Array<Pick<Favorite, 'id' | 'productId' | 'createdAt'>>;
  cart: Array<Pick<CartItem, 'id' | 'productId' | 'quantity' | 'createdAt' | 'updatedAt'>>;
  social: {
    following: Array<{ followingId: string; createdAt: Date }>;
    followers: Array<{ followerId: string; createdAt: Date }>;
    blocked: Array<{ blockedId: string; createdAt: Date }>;
    blockedBy: Array<{ blockerId: string; createdAt: Date }>;
  };
}
