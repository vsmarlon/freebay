import { MessageType } from '@prisma/client';

export type DirectConversationFixture = {
  id: string;
  user1Id: string;
  user2Id: string;
  status: 'ACTIVE' | 'PENDING';
  lastMessageAt: Date;
  createdAt: Date;
  user1: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  user2: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  messages: Array<{
    id: string;
    content: string | null;
    senderId: string;
    createdAt: Date;
    readAt: Date | null;
  }>;
};

export type OrderConversationFixture = {
  id: string;
  buyerId: string;
  sellerId: string;
  status: string;
  createdAt: Date;
  product: { id: string; title: string };
  buyer: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  seller: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  chatMessages: Array<{
    id: string;
    content: string | null;
    senderId: string;
    createdAt: Date;
    readAt: Date | null;
  }>;
  unreadCount?: number;
};

type MessageFixture = {
  id: string;
  senderId: string;
  content: string | null;
  type: MessageType;
  attachmentUrl: string | null;
  metadata: Record<string, unknown> | null;
  replyToId: string | null;
  replyTo: {
    id: string;
    senderId: string;
    content: string | null;
    type: MessageType;
    attachmentUrl: string | null;
    deletedAt: Date | null;
    viewOnce?: boolean;
    readAt?: Date | null;
  } | null;
  deletedAt: Date | null;
  readAt: Date | null;
  deliveredAt: Date | null;
  viewOnce: boolean;
  createdAt: Date;
};

export type DirectMessageFixture = MessageFixture & {
  conversationId: string;
  clientMessageId?: string | null;
  sender?: { id: string; displayName: string; avatarUrl: string | null };
};

export type OrderMessageFixture = MessageFixture & {
  orderId: string;
  clientMessageId?: string | null;
  sender?: { id: string; displayName: string; avatarUrl: string | null };
};

export function directConversation(
  overrides: Partial<DirectConversationFixture> = {},
): DirectConversationFixture {
  return {
    id: 'conv-1',
    user1Id: 'user-1',
    user2Id: 'user-2',
    status: 'ACTIVE',
    lastMessageAt: new Date('2026-06-24'),
    createdAt: new Date('2026-06-20'),
    user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
    user2: { id: 'user-2', displayName: 'Other', avatarUrl: null, isVerified: true },
    messages: [],
    ...overrides,
  };
}

export function orderConversation(
  overrides: Partial<OrderConversationFixture> = {},
): OrderConversationFixture {
  return {
    id: 'order-1',
    buyerId: 'user-1',
    sellerId: 'user-2',
    status: 'COMPLETED',
    createdAt: new Date('2026-06-22'),
    product: { id: 'prod-1', title: 'Camera' },
    buyer: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
    seller: { id: 'user-2', displayName: 'Other', avatarUrl: null, isVerified: true },
    chatMessages: [],
    unreadCount: 0,
    ...overrides,
  };
}

export function directMessage(
  overrides: Partial<DirectMessageFixture> = {},
): DirectMessageFixture {
  return {
    id: 'msg-1',
    conversationId: 'conv-1',
    senderId: 'user-1',
    content: 'Hello',
    type: 'TEXT',
    attachmentUrl: null,
    metadata: null,
    replyToId: null,
    replyTo: null,
    deletedAt: null,
    readAt: null,
    deliveredAt: null,
    viewOnce: false,
    createdAt: new Date('2026-06-24'),
    ...overrides,
  };
}

export function orderMessage(
  overrides: Partial<OrderMessageFixture> = {},
): OrderMessageFixture {
  return {
    id: 'msg-1',
    orderId: 'order-1',
    senderId: 'buyer-1',
    content: 'Hello',
    type: 'TEXT',
    attachmentUrl: null,
    metadata: null,
    replyToId: null,
    replyTo: null,
    deletedAt: null,
    readAt: null,
    deliveredAt: null,
    viewOnce: false,
    createdAt: new Date('2026-06-24'),
    ...overrides,
  };
}
