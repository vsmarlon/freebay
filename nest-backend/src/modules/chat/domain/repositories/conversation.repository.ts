import { RepositoryResponse } from '@/shared/core/either';
import { DirectConversation, User, Prisma, DirectMessage, ChatMessage, ConversationPreference, MessageReaction } from '@prisma/client';
import {
  DirectConversationWithDetails,
  OrderWithChat,
  DirectMessageWithSender,
  ChatMessageWithSender,
} from '../../mappers/conversation.mapper';

export abstract class ConversationRepository {
  abstract findDirectConversationById(id: string): RepositoryResponse<DirectConversation | null>;
  abstract findDirectConversationsByUser(userId: string): RepositoryResponse<DirectConversationWithDetails[]>;
  abstract findDirectConversationBetweenUsers(user1Id: string, user2Id: string): RepositoryResponse<DirectConversation | null>;
  abstract createDirectConversation(data: Prisma.DirectConversationCreateInput): RepositoryResponse<DirectConversation>;
  abstract updateDirectConversation(id: string, data: Prisma.DirectConversationUpdateInput): RepositoryResponse<DirectConversation>;
  abstract findUserById(id: string): RepositoryResponse<User | null>;
  abstract findFollow(followerId: string, followingId: string): RepositoryResponse<{ id: string } | null>;
  abstract createDirectMessage(data: Prisma.DirectMessageCreateInput, includeSender?: boolean): RepositoryResponse<DirectMessage | DirectMessageWithSender>;
  abstract findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null>;
  abstract softDeleteDirectMessage(id: string): RepositoryResponse<void>;
  abstract findMessagesByConversation(conversationId: string): RepositoryResponse<DirectMessageWithSender[]>;
  abstract markMessagesDelivered(conversationId: string, userId: string): RepositoryResponse<void>;
  abstract markMessagesRead(conversationId: string, userId: string): RepositoryResponse<void>;
  abstract createChatMessage(data: Prisma.ChatMessageCreateInput, includeSender?: boolean): RepositoryResponse<ChatMessage | ChatMessageWithSender>;
  abstract findChatMessagesByOrder(orderId: string): RepositoryResponse<ChatMessageWithSender[]>;
  abstract markChatMessagesRead(orderId: string, userId: string): RepositoryResponse<void>;
  abstract findOrdersByUser(userId: string): RepositoryResponse<OrderWithChat[]>;
  abstract countUnreadChatMessages(orderIds: string[], userId: string): RepositoryResponse<Record<string, number>>;
  abstract findPreferencesByUser(userId: string): RepositoryResponse<ConversationPreference[]>;
  abstract findReactionByUserAndMessage(userId: string, messageId: string, model: 'DIRECT' | 'ORDER'): RepositoryResponse<MessageReaction | null>;
  abstract upsertReaction(data: { userId: string; messageId: string; emoji: string; model: 'DIRECT' | 'ORDER' }): RepositoryResponse<void>;
  abstract deleteReaction(reactionId: string): RepositoryResponse<void>;
  abstract getReactionsForMessage(messageId: string, model: 'DIRECT' | 'ORDER'): RepositoryResponse<{ emoji: string; userId: string }[]>;
}
