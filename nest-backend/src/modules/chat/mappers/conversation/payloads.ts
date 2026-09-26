import { Prisma } from '@prisma/client';
import { USER_SELECT_BASIC, USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';

export const directConversationWithDetailsValidator = Prisma.validator<Prisma.DirectConversationDefaultArgs>()({
  include: {
    user1: { select: USER_SELECT_BASIC },
    user2: { select: USER_SELECT_BASIC },
    product: {
      select: {
        id: true,
        title: true,
        status: true,
        images: { select: { url: true }, orderBy: { order: 'asc' }, take: 1 },
      },
    },
    messages: {
      take: 1,
      select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
      orderBy: { createdAt: 'desc' },
    },
    _count: {
      select: { messages: true },
    },
  },
});

export type DirectConversationWithDetails = Prisma.DirectConversationGetPayload<typeof directConversationWithDetailsValidator>;

export const productConversationSummaryValidator = Prisma.validator<Prisma.ProductDefaultArgs>()({
  select: {
    id: true,
    title: true,
    sellerId: true,
    status: true,
    images: { select: { url: true }, orderBy: { order: 'asc' }, take: 1 },
  },
});

export type ProductConversationSummaryRecord = Prisma.ProductGetPayload<typeof productConversationSummaryValidator>;

export const orderWithChatValidator = Prisma.validator<Prisma.OrderDefaultArgs>()({
  include: {
    buyer: { select: USER_SELECT_BASIC },
    seller: { select: USER_SELECT_BASIC },
    product: { select: { id: true, title: true } },
    chatMessages: {
      take: 1,
      select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
      orderBy: { createdAt: 'desc' },
    },
  },
});

export type OrderWithChatRecord = Prisma.OrderGetPayload<typeof orderWithChatValidator>;
export type OrderWithChat = OrderWithChatRecord & { unreadCount: number };

const replyToSelect = {
  id: true,
  senderId: true,
  content: true,
  type: true,
  attachmentUrl: true,
  deletedAt: true,
  createdAt: true,
  viewOnce: true,
  readAt: true,
} as const;

export const messageWithSenderInclude = {
  sender: { select: USER_SELECT_MINIMAL },
  replyTo: { select: replyToSelect },
} as const;

export const directMessageWithSenderValidator = Prisma.validator<Prisma.DirectMessageDefaultArgs>()({
  include: messageWithSenderInclude,
});

export type DirectMessageWithSender = Prisma.DirectMessageGetPayload<typeof directMessageWithSenderValidator>;

export const chatMessageWithSenderValidator = Prisma.validator<Prisma.ChatMessageDefaultArgs>()({
  include: messageWithSenderInclude,
});

export type ChatMessageWithSender = Prisma.ChatMessageGetPayload<typeof chatMessageWithSenderValidator>;

export type ReplyToSummary = {
  id: string;
  senderId: string;
  content: string | null;
  type: string;
  attachmentUrl: string | null;
  deletedAt: Date | null;
  conversationId: string;
  createdAt: Date;
  viewOnce: boolean;
  readAt: Date | null;
};
