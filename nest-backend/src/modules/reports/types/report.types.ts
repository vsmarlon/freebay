import { Prisma, ReportTargetType, ReportReason } from '@prisma/client';

export type DirectMessageWithConversation = Prisma.DirectMessageGetPayload<{ include: { conversation: true } }>;

export type ChatMessageWithOrder = Prisma.ChatMessageGetPayload<{ include: { order: true } }>;

export interface CreateReportData {
  reporterId: string;
  reportedUserId?: string;
  reportedPostId?: string;
  targetType: ReportTargetType;
  reportedDirectConversationId?: string;
  reportedOrderChatId?: string;
  reportedDirectMessageId?: string;
  reportedChatMessageId?: string;
  reason: ReportReason;
  description?: string | null;
  hideFromUser?: boolean;
}
