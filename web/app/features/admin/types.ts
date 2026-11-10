export type DisputeStatus =
  | 'OPEN'
  | 'AWAITING_SELLER'
  | 'AWAITING_BUYER'
  | 'ESCALATED'
  | 'RESOLVED'
  | 'CANCELLED';

export type DisputeWinner = 'BUYER' | 'SELLER';

export type AdminUser = {
  id: string;
  displayName: string;
  username?: string | null;
  avatarUrl?: string | null;
};

export type AdminDispute = {
  id: string;
  orderId: string;
  openedById: string;
  status: DisputeStatus;
  reason: string;
  buyerEvidence: unknown;
  sellerEvidence: unknown;
  winner: DisputeWinner | null;
  resolution: string | null;
  resolvedAt: string | null;
  createdAt: string;
  expiresAt: string;
  order: {
    id: string;
    buyerId: string;
    sellerId: string;
    amount: number;
    status: string;
    buyer: AdminUser;
    seller: AdminUser;
    product: { title: string; imageUrl?: string | null };
  };
  openedBy: { id: string; displayName: string };
};

export type ReportStatus = 'PENDING' | 'REVIEWED' | 'RESOLVED' | 'REJECTED';

export type AdminReport = {
  id: string;
  targetType: string;
  reason: string;
  description: string | null;
  status: ReportStatus;
  createdAt: string;
  reviewedAt: string | null;
  reporter: AdminUser;
  reportedUser: AdminUser | null;
  reportedPostId: string | null;
  reportedDirectConversationId: string | null;
  reportedOrderChatId: string | null;
  reportedDirectMessageId: string | null;
  reportedChatMessageId: string | null;
};
