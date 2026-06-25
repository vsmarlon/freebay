import { DirectConversation, DirectMessage, ChatMessage, ConversationPreference, User } from '@prisma/client';

export type DirectConversationWithDetails = DirectConversation & {
  user1: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
  user2: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
  messages: Pick<DirectMessage, 'id' | 'content' | 'senderId' | 'createdAt' | 'readAt'>[];
};

export type OrderWithChat = {
  id: string;
  buyerId: string;
  sellerId: string;
  status: string;
  createdAt: Date;
  buyer: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
  seller: Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
  product: { id: string; title: string };
  chatMessages: Pick<ChatMessage, 'id' | 'content' | 'senderId' | 'createdAt' | 'readAt'>[];
};

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

export type DirectMessageWithSender = DirectMessage & {
  sender: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
};

export type ChatMessageWithSender = ChatMessage & {
  sender: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
};

export class ConversationMapper {
  static toUnifiedDirect(
    conv: DirectConversationWithDetails,
    userId: string,
    preference?: ConversationPreference | null,
  ): UnifiedConversationResponse {
    const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
    const lastMsg = conv.messages[0];
    const unreadCount = conv.messages.filter(m =>
      m.senderId !== userId && !m.readAt
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
    const messages = order.chatMessages ?? [];
    const lastMsg = messages[messages.length - 1] ?? null;
    const unreadCount = messages.filter(m =>
      m.senderId !== userId && !m.readAt
    ).length;

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
        content: lastMsg.content,
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

  static toMessageResponse(msg: DirectMessageWithSender | ChatMessageWithSender, conversationId: string): {
    id: string;
    conversationId: string;
    senderId: string;
    content: string | null;
    sender: { id: string; displayName: string; avatarUrl: string | null };
    readAt: string | null;
    deliveredAt: string | null;
    createdAt: string;
  } {
    return {
      id: msg.id,
      conversationId,
      senderId: msg.senderId,
      content: 'content' in msg ? (msg.content ?? null) : null,
      sender: {
        id: msg.sender.id,
        displayName: msg.sender.displayName,
        avatarUrl: msg.sender.avatarUrl,
      },
      readAt: 'readAt' in msg && msg.readAt ? msg.readAt.toISOString() : null,
      deliveredAt: 'deliveredAt' in msg && msg.deliveredAt ? msg.deliveredAt.toISOString() : null,
      createdAt: msg.createdAt.toISOString(),
    };
  }
}
