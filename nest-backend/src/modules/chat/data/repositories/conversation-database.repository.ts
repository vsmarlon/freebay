import { Injectable } from '@nestjs/common';
import { Prisma, DirectConversation, User, DirectMessage, ChatMessage, ChatThreadType, ConversationPreference, MessageReaction, MessageType, StarredMessage } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { DirectConversationWithDetails, OrderWithChatRecord, DirectMessageWithSender, ChatMessageWithSender, ReplyToSummary, ProductConversationSummaryRecord, ConversationStartRecord } from '../../mappers/conversation.mapper';
import * as lookups from './conversation/lookups';
import * as messages from './conversation/messages';
import * as reactions from './conversation/reactions-media';

@Injectable()
export class ConversationDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  findUserById(id: string): RepositoryResponse<User | null> { return repositoryResponse(() => lookups.findUserById(this.prisma, id), 'Erro ao buscar usuário', this.constructor.name); }
  findFollow(followerId: string, followingId: string): RepositoryResponse<{ id: string } | null> { return repositoryResponse(() => lookups.findFollow(this.prisma, followerId, followingId), 'Erro ao buscar relacionamento', this.constructor.name); }
  findDirectConversationById(id: string): RepositoryResponse<DirectConversation | null> { return repositoryResponse(() => lookups.findDirectConversationById(this.prisma, id), 'Erro ao buscar conversa', this.constructor.name); }
  findDirectConversationsByUser(userId: string): RepositoryResponse<DirectConversationWithDetails[]> { return repositoryResponse(() => lookups.findDirectConversationsByUser(this.prisma, userId), 'Erro ao buscar conversas'); }
  findDirectConversationBetweenUsers(user1Id: string, user2Id: string, scopeKey = 'DIRECT'): RepositoryResponse<ConversationStartRecord | null> { return repositoryResponse(() => lookups.findDirectConversationBetweenUsers(this.prisma, user1Id, user2Id, scopeKey), 'Erro ao buscar conversa'); }
  findProductConversationBetweenUsers(user1Id: string, user2Id: string, productId: string): RepositoryResponse<ConversationStartRecord | null> { return this.findDirectConversationBetweenUsers(user1Id, user2Id, `PRODUCT:${productId}`); }
  findProductSummary(productId: string): RepositoryResponse<ProductConversationSummaryRecord | null> { return repositoryResponse(() => lookups.findProductSummary(this.prisma, productId), 'Erro ao buscar produto'); }
  createDirectConversation(data: Prisma.DirectConversationCreateInput): RepositoryResponse<ConversationStartRecord> { return lookups.createDirectConversation(this.prisma, data); }
  updateDirectConversation(id: string, data: Prisma.DirectConversationUpdateInput): RepositoryResponse<DirectConversation> { return repositoryResponse(() => lookups.updateDirectConversation(this.prisma, id, data), 'Erro ao atualizar conversa'); }

  findDirectMessageByClientId(conversationId: string, senderId: string, clientMessageId: string): RepositoryResponse<DirectMessage | null> { return repositoryResponse(() => messages.findDirectMessageByClientId(this.prisma, conversationId, senderId, clientMessageId), 'Erro ao buscar mensagem existente'); }
  createDirectMessage(data: Prisma.DirectMessageCreateInput, includeSender?: boolean): RepositoryResponse<DirectMessage | DirectMessageWithSender> { return messages.createDirectMessage(this.prisma, data, includeSender); }
  findMessagesByConversation(conversationId: string, page: PageQuery): RepositoryResponse<CursorPage<DirectMessageWithSender>> { return repositoryResponse(() => messages.findMessagesByConversation(this.prisma, conversationId, page), 'Erro ao buscar mensagens'); }
  createChatMessage(data: Prisma.ChatMessageCreateInput, includeSender?: boolean): RepositoryResponse<ChatMessage | ChatMessageWithSender> { return messages.createChatMessage(this.prisma, data, includeSender); }
  findChatMessageByClientId(orderId: string, senderId: string, clientMessageId: string): RepositoryResponse<ChatMessage | null> { return repositoryResponse(() => messages.findChatMessageByClientId(this.prisma, orderId, senderId, clientMessageId), 'Erro ao buscar mensagem existente'); }
  findChatMessagesByOrder(orderId: string, page: PageQuery): RepositoryResponse<CursorPage<ChatMessageWithSender>> { return repositoryResponse(() => messages.findChatMessagesByOrder(this.prisma, orderId, page), 'Erro ao buscar mensagens'); }
  markChatMessagesRead(orderId: string, userId: string): RepositoryResponse<void> { return repositoryResponse(async () => { await messages.markChatMessagesRead(this.prisma, orderId, userId); }, 'Erro ao marcar mensagens'); }
  markMessagesDelivered(conversationId: string, userId: string): RepositoryResponse<void> { return repositoryResponse(async () => { await messages.markMessagesDelivered(this.prisma, conversationId, userId); }, 'Erro ao marcar mensagens'); }
  markMessagesRead(conversationId: string, userId: string): RepositoryResponse<void> { return repositoryResponse(async () => { await messages.markMessagesRead(this.prisma, conversationId, userId); }, 'Erro ao marcar mensagens'); }

  findOrdersByUser(userId: string): RepositoryResponse<OrderWithChatRecord[]> { return repositoryResponse(() => lookups.findOrdersByUser(this.prisma, userId), 'Erro ao buscar pedidos'); }
  countUnreadChatMessages(orderIds: string[], userId: string): RepositoryResponse<Record<string, number>> { return repositoryResponse(() => lookups.countUnreadChatMessages(this.prisma, orderIds, userId), 'Erro ao contar mensagens'); }
  findPreferencesByUser(userId: string): RepositoryResponse<ConversationPreference[]> { return repositoryResponse(() => lookups.findPreferencesByUser(this.prisma, userId), 'Erro ao buscar preferências'); }

  findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null> { return repositoryResponse(() => messages.findDirectMessageById(this.prisma, id), 'Erro ao buscar mensagem'); }
  softDeleteDirectMessage(id: string): RepositoryResponse<void> { return repositoryResponse(() => messages.softDeleteDirectMessage(this.prisma, id), 'Erro ao apagar mensagem'); }
  findReactionByUserAndMessage(userId: string, messageId: string, model: ChatThreadType): RepositoryResponse<MessageReaction | null> { return repositoryResponse(() => reactions.findReactionByUserAndMessage(this.prisma, userId, messageId, model), 'Erro ao buscar reação'); }
  upsertReaction(data: { userId: string; messageId: string; emoji: string; model: ChatThreadType }): RepositoryResponse<void> { return repositoryResponse(() => reactions.upsertReaction(this.prisma, data), 'Erro ao registrar reação'); }
  deleteReaction(reactionId: string): RepositoryResponse<void> { return repositoryResponse(async () => { await reactions.deleteReaction(this.prisma, reactionId); }, 'Erro ao remover reação'); }
  getReactionsForMessage(messageId: string, model: ChatThreadType): RepositoryResponse<{ emoji: string; userId: string }[]> { return repositoryResponse(() => reactions.getReactionsForMessage(this.prisma, messageId, model), 'Erro ao buscar reações'); }
  findStarByUserAndMessage(userId: string, messageId: string, model: ChatThreadType): RepositoryResponse<StarredMessage | null> { return repositoryResponse(() => reactions.findStarByUserAndMessage(this.prisma, userId, messageId, model), 'Erro ao buscar favorita'); }
  createStar(data: { userId: string; messageId: string; model: ChatThreadType }): RepositoryResponse<void> { return repositoryResponse(async () => { await reactions.createStar(this.prisma, data); }, 'Erro ao favoritar mensagem'); }
  deleteStar(starId: string): RepositoryResponse<void> { return repositoryResponse(async () => { await reactions.deleteStar(this.prisma, starId); }, 'Erro ao desfavoritar mensagem'); }
  findStarredMessages(userId: string, threadId: string, model: ChatThreadType): RepositoryResponse<(DirectMessageWithSender | ChatMessageWithSender)[]> { return repositoryResponse(() => reactions.findStarredMessages(this.prisma, userId, threadId, model), 'Erro ao buscar favoritas'); }

  findDirectMessagesByType(conversationId: string, type: MessageType, limit: number, cursor?: string): RepositoryResponse<DirectMessageWithSender[]> { return repositoryResponse(() => messages.findDirectMessagesByType(this.prisma, conversationId, type, limit, cursor), 'Erro ao buscar mensagens'); }
  findChatMessagesByType(orderId: string, type: MessageType, limit: number, cursor?: string): RepositoryResponse<ChatMessageWithSender[]> { return repositoryResponse(() => messages.findChatMessagesByType(this.prisma, orderId, type, limit, cursor), 'Erro ao buscar mensagens'); }
  messageBelongsToThread(messageId: string, threadId: string, model: ChatThreadType): RepositoryResponse<boolean> { return repositoryResponse(() => messages.messageBelongsToThread(this.prisma, messageId, threadId, model), 'Erro ao verificar mensagem da conversa'); }
  findReplyToSummary(id: string): RepositoryResponse<ReplyToSummary | null> { return repositoryResponse(() => messages.findReplyToSummary(this.prisma, id), 'Erro ao buscar mensagem referenciada'); }
}
