import { Prisma, ConversationPreference } from '@prisma/client';
import { USER_SELECT_BASIC, USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';

// ─── Prisma Typed Includes & Payloads ──────────────────────────────────────────

export const directConversationWithDetailsValidator = Prisma.validator<Prisma.DirectConversationDefaultArgs>()({
  include: {
    user1: { select: USER_SELECT_BASIC },
    user2: { select: USER_SELECT_BASIC },
    messages: {
      take: 1,
      select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
      orderBy: { createdAt: 'desc' },
    },
    _count: {
      select: {
        messages: true,
      },
    },
  },
});

export type DirectConversationWithDetails = Prisma.DirectConversationGetPayload<typeof directConversationWithDetailsValidator>;

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

export const directMessageWithSenderValidator = Prisma.validator<Prisma.DirectMessageDefaultArgs>()({
  include: {
    sender: { select: USER_SELECT_MINIMAL },
    replyTo: {
      select: {
        id: true,
        senderId: true,
        content: true,
        type: true,
        attachmentUrl: true,
        deletedAt: true,
        createdAt: true,
        viewOnce: true,
        readAt: true,
      },
    },
  },
});

export type DirectMessageWithSender = Prisma.DirectMessageGetPayload<typeof directMessageWithSenderValidator>;

export const chatMessageWithSenderValidator = Prisma.validator<Prisma.ChatMessageDefaultArgs>()({
  include: {
    sender: { select: USER_SELECT_MINIMAL },
    replyTo: {
      select: {
        id: true,
        senderId: true,
        content: true,
        type: true,
        attachmentUrl: true,
        deletedAt: true,
        createdAt: true,
        viewOnce: true,
        readAt: true,
      },
    },
  },
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

// ─── API DTO Response Interfaces ───────────────────────────────────────────────

export interface UnifiedConversationResponse {
  id: string;
  threadType: 'DIRECT' | 'ORDER';
  otherUser: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
  orderInfo?: {
    id: string;
    productTitle: string;
    status: string;
  };
  lastMessage: {
    content: string;
    createdAt: string;
    senderId: string;
  } | null;
  unreadCount: number;
  status: string;
  createdAt: string;
  preference: {
    isArchived: boolean;
    theme: string;
    backgroundUrl: string | null;
  } | null;
}

export interface MessageResponseDto {
  id: string;
  conversationId: string;
  senderId: string;
  content: string | null;
  sender: { id: string; displayName: string; avatarUrl: string | null };
  readAt: string | null;
  deliveredAt: string | null;
  createdAt: string;
  viewOnce: boolean;
}

// ─── Conversation Mapper ───────────────────────────────────────────────────────

export class ConversationMapper {
  static toUnifiedDirect(
    conv: DirectConversationWithDetails,
    userId: string,
    preference?: ConversationPreference | null,
  ): UnifiedConversationResponse {
    const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
    const lastMsg = conv.messages?.[0] ?? null;
    const unreadCount =
      conv._count?.messages ??
      (conv.messages ?? []).filter(
        (m) => m.senderId !== userId && !m.readAt,
      ).length;

    return {
      id: conv.id,
      threadType: 'DIRECT',
      otherUser: {
        id: otherUser.id,
        displayName: otherUser.displayName,
        avatarUrl: otherUser.avatarUrl,
        isVerified: otherUser.isVerified,
      },
      lastMessage: lastMsg ? {
        content: lastMsg.content ?? '',
        createdAt: lastMsg.createdAt.toISOString(),
        senderId: lastMsg.senderId,
      } : null,
      unreadCount,
      status: conv.status,
      createdAt: conv.createdAt.toISOString(),
      preference: preference ? {
        isArchived: preference.isArchived,
        theme: preference.theme,
        backgroundUrl: preference.backgroundUrl,
      } : null,
    };
  }

  static toUnifiedOrder(
    order: OrderWithChat,
    userId: string,
    preference?: ConversationPreference | null,
  ): UnifiedConversationResponse {
    const otherUser = order.buyerId === userId ? order.seller : order.buyer;
    const lastMsg = order.chatMessages?.[0] ?? null;
    const unreadCount = order.unreadCount;

    return {
      id: order.id,
      threadType: 'ORDER',
      otherUser: {
        id: otherUser.id,
        displayName: otherUser.displayName,
        avatarUrl: otherUser.avatarUrl,
        isVerified: otherUser.isVerified,
      },
      orderInfo: {
        id: order.id,
        productTitle: order.product.title,
        status: order.status,
      },
      lastMessage: lastMsg ? {
        content: lastMsg.content ?? '',
        createdAt: lastMsg.createdAt.toISOString(),
        senderId: lastMsg.senderId,
      } : null,
      unreadCount,
      status: order.status,
      createdAt: order.createdAt.toISOString(),
      preference: preference ? {
        isArchived: preference.isArchived,
        theme: preference.theme,
        backgroundUrl: preference.backgroundUrl,
      } : null,
    };
  }

  static toMessageResponse(
    msg: DirectMessageWithSender | ChatMessageWithSender,
    conversationId: string,
  ): MessageResponseDto {
    const isViewOnceHidden = msg.viewOnce && 'readAt' in msg && msg.readAt !== null;

    return {
      id: msg.id,
      conversationId,
      senderId: msg.senderId,
      content: isViewOnceHidden ? null : ('content' in msg ? (msg.content ?? null) : null),
      sender: {
        id: msg.sender.id,
        displayName: msg.sender.displayName,
        avatarUrl: msg.sender.avatarUrl,
      },
      readAt: 'readAt' in msg && msg.readAt ? msg.readAt.toISOString() : null,
      deliveredAt: 'deliveredAt' in msg && msg.deliveredAt ? msg.deliveredAt.toISOString() : null,
      createdAt: msg.createdAt.toISOString(),
      viewOnce: msg.viewOnce,
    };
  }
}
