import { ChatThreadType, ConversationPreference, User } from '@prisma/client';
import { ConversationCounterpartSummary, ProductConversationSummary, StartConversationOutput } from './chat.dto';
import {
  DirectConversationWithDetails,
  DirectMessageWithSender,
  OrderWithChat,
  ProductConversationSummaryRecord,
  ReplyToSummary,
} from '../data/repositories/conversation/payloads';

export function toProductConversationSummary(product: ProductConversationSummaryRecord): ProductConversationSummary {
  return { id: product.id, title: product.title, imageUrl: product.images[0]?.url ?? null, status: product.status };
}

export type ConversationStartRecord = {
  conversationId: string;
  status: string;
  threadType: ChatThreadType;
  product: ProductConversationSummary | null;
};

export function toCounterpartSummary(user: Pick<User, 'id' | 'displayName' | 'avatarUrl'>): ConversationCounterpartSummary {
  return { id: user.id, displayName: user.displayName, avatarUrl: user.avatarUrl };
}

export function toStartConversationOutput(conversation: ConversationStartRecord, user: Pick<User, 'id' | 'displayName' | 'avatarUrl'>): StartConversationOutput {
  return {
    conversationId: conversation.conversationId,
    status: conversation.status,
    threadType: ChatThreadType.DIRECT,
    otherUser: toCounterpartSummary(user),
    product: conversation.product,
  };
}

type RedactableReply = Pick<ReplyToSummary, 'content' | 'attachmentUrl' | 'deletedAt' | 'viewOnce' | 'readAt'>;

export function redactReplySummary<T extends RedactableReply>(reply: T): T {
  return reply.deletedAt !== null || (reply.viewOnce && reply.readAt !== null)
    ? { ...reply, content: null, attachmentUrl: null }
    : reply;
}

export interface UnifiedConversationResponse {
  id: string;
  threadType: ChatThreadType;
  otherUser: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  orderInfo?: { id: string; productTitle: string; status: string };
  product?: { id: string; title: string; imageUrl: string | null; status: string };
  lastMessage: { content: string; createdAt: string; senderId: string } | null;
  unreadCount: number;
  status: string;
  createdAt: string;
  preference: { isArchived: boolean; theme: string; backgroundUrl: string | null } | null;
}

type UnifiedUser = Pick<User, 'id' | 'displayName' | 'avatarUrl' | 'isVerified'>;
type UnifiedLastMessage = Pick<DirectMessageWithSender, 'content' | 'createdAt' | 'senderId'>;

function unifiedConversationFields(otherUser: UnifiedUser, lastMsg: UnifiedLastMessage | null, unreadCount: number, status: string, createdAt: Date, preference?: ConversationPreference | null): Omit<UnifiedConversationResponse, 'id' | 'threadType' | 'product' | 'orderInfo'> {
  return {
    otherUser,
    lastMessage: lastMsg ? { content: lastMsg.content ?? '', createdAt: lastMsg.createdAt.toISOString(), senderId: lastMsg.senderId } : null,
    unreadCount,
    status,
    createdAt: createdAt.toISOString(),
    preference: preference ? { isArchived: preference.isArchived, theme: preference.theme, backgroundUrl: preference.backgroundUrl } : null,
  };
}

export function toUnifiedDirect(conv: DirectConversationWithDetails, userId: string, preference?: ConversationPreference | null): UnifiedConversationResponse {
  const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
  const lastMsg = conv.messages?.[0] ?? null;
  const unreadCount = conv._count?.messages ?? (conv.messages ?? []).filter((message) => message.senderId !== userId && !message.readAt).length;
  return {
    id: conv.id,
    threadType: ChatThreadType.DIRECT,
    ...(conv.product ? { product: { id: conv.product.id, title: conv.product.title, imageUrl: conv.product.images[0]?.url ?? null, status: conv.product.status } } : {}),
    ...unifiedConversationFields(otherUser, lastMsg, unreadCount, conv.status, conv.createdAt, preference),
  };
}

export function toUnifiedOrder(order: OrderWithChat, userId: string, preference?: ConversationPreference | null): UnifiedConversationResponse {
  const otherUser = order.buyerId === userId ? order.seller : order.buyer;
  const lastMsg = order.chatMessages?.[0] ?? null;
  return {
    id: order.id,
    threadType: ChatThreadType.ORDER,
    orderInfo: { id: order.id, productTitle: order.product.title, status: order.status },
    ...unifiedConversationFields(otherUser, lastMsg, order.unreadCount, order.status, order.createdAt, preference),
  };
}
