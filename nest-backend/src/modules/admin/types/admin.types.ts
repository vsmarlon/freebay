import {
  ModerationActionType,
  ModerationTargetType,
  ReportReason,
  ReportStatus,
  ReportTargetType,
} from '@prisma/client';

export interface AdminUserBrief {
  id: string;
  displayName: string;
  username: string | null;
  avatarUrl: string | null;
  suspendedAt: Date | null;
}

export interface AdminReportRow {
  id: string;
  targetType: ReportTargetType;
  reason: ReportReason;
  description: string | null;
  status: ReportStatus;
  createdAt: Date;
  reviewedAt: Date | null;
  reporter: AdminUserBrief;
  reportedUser: AdminUserBrief | null;
  reportedPostId: string | null;
  reportedDirectConversationId: string | null;
  reportedOrderChatId: string | null;
  reportedDirectMessageId: string | null;
  reportedChatMessageId: string | null;
  reviewedById: string | null;
}

export interface ModerationActionRow {
  id: string;
  actorId: string;
  actorDisplayName: string;
  targetType: ModerationTargetType;
  targetId: string;
  action: ModerationActionType;
  reason: string | null;
  reportId: string | null;
  createdAt: Date;
}

export interface CreateModerationActionInput {
  actorId: string;
  targetType: ModerationTargetType;
  targetId: string;
  action: ModerationActionType;
  reason?: string | null;
  reportId?: string | null;
}

export interface TransferFailureRow {
  transactionId: string;
  orderId: string;
  sellerId: string;
  sellerAmount: number;
  transferState: string;
  transferAttempts: number;
  transferProcessingAt: Date | null;
  transferId: string | null;
  transferLastError: string | null;
  reversalState: string;
  reversalAttempts: number;
  reversalProcessingAt: Date | null;
  reversalId: string | null;
  reversalLastError: string | null;
}
