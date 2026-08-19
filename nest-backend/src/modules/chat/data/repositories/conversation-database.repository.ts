import { Injectable } from '@nestjs/common';
import { Prisma, DirectConversation, User, DirectMessage, ChatMessage, ChatThreadType, ConversationPreference, MessageReaction, MessageType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationRepository } from '../../domain/repositories/conversation.repository';
import { USER_SELECT_BASIC, USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import {
  DirectConversationWithDetails,
  OrderWithChatRecord,
  DirectMessageWithSender,
  ChatMessageWithSender,
  ReplyToSummary,
} from '../../mappers/conversation.mapper';

const REPLY_TO_SELECT = {
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

@Injectable()
export class ConversationDatabaseRepository implements ConversationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findUserById(id: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { id } }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar usuário')); }
  }

  async findFollow(followerId: string, followingId: string): RepositoryResponse<{ id: string } | null> {
    try {
      const follow = await this.prisma.follow.findFirst({
        where: { followerId, followingId },
        select: { id: true },
      });
      return right(follow);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar relacionamento')); }
  }

  async findDirectConversationById(id: string): RepositoryResponse<DirectConversation | null> {
    try {
      return right(await this.prisma.directConversation.findUnique({ where: { id } }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar conversa')); }
  }

  async findDirectConversationsByUser(userId: string): RepositoryResponse<DirectConversationWithDetails[]> {
    try {
      const convs = await this.prisma.directConversation.findMany({
        where: {
          OR: [
            { user1Id: userId },
            { user2Id: userId },
          ],
        },
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
              messages: {
                where: {
                  senderId: { not: userId },
                  readAt: null,
                },
              },
            },
          },
        },
        orderBy: { lastMessageAt: 'desc' },
      });
      return right(convs as DirectConversationWithDetails[]);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar conversas')); }
  }

  async findDirectConversationBetweenUsers(user1Id: string, user2Id: string): RepositoryResponse<DirectConversation | null> {
    try {
      return right(await this.prisma.directConversation.findFirst({
        where: {
          OR: [
            { user1Id, user2Id },
            { user1Id: user2Id, user2Id: user1Id },
          ],
        },
      }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar conversa')); }
  }

  async createDirectConversation(data: Prisma.DirectConversationCreateInput): RepositoryResponse<DirectConversation> {
    try {
      return right(await this.prisma.directConversation.create({ data }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao criar conversa')); }
  }

  async updateDirectConversation(id: string, data: Prisma.DirectConversationUpdateInput): RepositoryResponse<DirectConversation> {
    try {
      return right(await this.prisma.directConversation.update({ where: { id }, data }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao atualizar conversa')); }
  }

  async createDirectMessage(data: Prisma.DirectMessageCreateInput, includeSender?: boolean): RepositoryResponse<DirectMessage | DirectMessageWithSender> {
    try {
      const query: Prisma.DirectMessageCreateArgs = { data };
      if (includeSender) {
        query.include = { sender: { select: USER_SELECT_MINIMAL } };
      }
      return right(await this.prisma.directMessage.create(query) as DirectMessage | DirectMessageWithSender);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao criar mensagem')); }
  }

  async findMessagesByConversation(conversationId: string): RepositoryResponse<DirectMessageWithSender[]> {
    try {
      return right(await this.prisma.directMessage.findMany({
        where: { conversationId },
        orderBy: { createdAt: 'asc' },
        include: {
          sender: { select: USER_SELECT_MINIMAL },
          replyTo: { select: REPLY_TO_SELECT },
        },
      }) as DirectMessageWithSender[]);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar mensagens')); }
  }

  async createChatMessage(data: Prisma.ChatMessageCreateInput, includeSender?: boolean): RepositoryResponse<ChatMessage | ChatMessageWithSender> {
    try {
      const query: Prisma.ChatMessageCreateArgs = { data };
      if (includeSender) {
        query.include = { sender: { select: USER_SELECT_MINIMAL } };
      }
      return right(await this.prisma.chatMessage.create(query) as ChatMessage | ChatMessageWithSender);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao criar mensagem')); }
  }

  async findChatMessagesByOrder(orderId: string): RepositoryResponse<ChatMessageWithSender[]> {
    try {
      return right(await this.prisma.chatMessage.findMany({
        where: { orderId },
        orderBy: { createdAt: 'asc' },
        include: {
          sender: { select: USER_SELECT_MINIMAL },
          replyTo: { select: REPLY_TO_SELECT },
        },
      }) as ChatMessageWithSender[]);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar mensagens')); }
  }

  async markChatMessagesRead(orderId: string, userId: string): RepositoryResponse<void> {
    try {
      await this.prisma.chatMessage.updateMany({
        where: { orderId, senderId: { not: userId }, readAt: null },
        data: { readAt: new Date(), deliveredAt: new Date() },
      });
      return right(void 0);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao marcar mensagens')); }
  }

  async markMessagesDelivered(conversationId: string, userId: string): RepositoryResponse<void> {
    try {
      await this.prisma.directMessage.updateMany({
        where: { conversationId, senderId: { not: userId }, deliveredAt: null },
        data: { deliveredAt: new Date() },
      });
      return right(void 0);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao marcar mensagens')); }
  }

  async markMessagesRead(conversationId: string, userId: string): RepositoryResponse<void> {
    try {
      await this.prisma.directMessage.updateMany({
        where: { conversationId, senderId: { not: userId }, readAt: null },
        data: { readAt: new Date(), deliveredAt: new Date() },
      });
      return right(void 0);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao marcar mensagens')); }
  }

  async findOrdersByUser(userId: string): RepositoryResponse<OrderWithChatRecord[]> {
    try {
      const orders = await this.prisma.order.findMany({
        where: {
          OR: [
            { buyerId: userId },
            { sellerId: userId },
          ],
        },
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
        orderBy: { updatedAt: 'desc' },
      });
      return right(orders);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar pedidos')); }
  }

  async countUnreadChatMessages(orderIds: string[], userId: string): RepositoryResponse<Record<string, number>> {
    try {
      if (orderIds.length === 0) return right({});
      const grouped = await this.prisma.chatMessage.groupBy({
        by: ['orderId'],
        where: {
          orderId: { in: orderIds },
          senderId: { not: userId },
          readAt: null,
        },
        _count: { id: true },
      });
      const map: Record<string, number> = {};
      for (const g of grouped) map[g.orderId] = g._count.id;
      return right(map);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao contar mensagens')); }
  }

  async findPreferencesByUser(userId: string): RepositoryResponse<ConversationPreference[]> {
    try {
      return right(await this.prisma.conversationPreference.findMany({
        where: { userId, isDeleted: false },
      }));
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar preferências')); }
  }

  async findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null> {
    try {
      const msg = await this.prisma.directMessage.findUnique({ where: { id } });
      return right(msg);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar mensagem')); }
  }

  async softDeleteDirectMessage(id: string): RepositoryResponse<void> {
    try {
      await this.prisma.directMessage.update({ where: { id }, data: { deletedAt: new Date() } });
      return right(undefined);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao apagar mensagem')); }
  }

  async findReactionByUserAndMessage(userId: string, messageId: string, model: ChatThreadType): RepositoryResponse<MessageReaction | null> {
    try {
      const where = model === 'DIRECT'
        ? { userId, directMessageId: messageId }
        : { userId, chatMessageId: messageId };
      const reaction = await this.prisma.messageReaction.findFirst({ where });
      return right(reaction);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar reação')); }
  }

  async upsertReaction(data: { userId: string; messageId: string; emoji: string; model: ChatThreadType }): RepositoryResponse<void> {
    try {
      const existing = await this.findReactionByUserAndMessage(data.userId, data.messageId, data.model);
      if (existing.isRight() && existing.value) {
        await this.prisma.messageReaction.update({
          where: { id: existing.value.id },
          data: { emoji: data.emoji },
        });
      } else {
        const msgField = data.model === 'DIRECT' ? 'directMessageId' : 'chatMessageId';
        await this.prisma.messageReaction.create({
          data: {
            userId: data.userId,
            [msgField]: data.messageId,
            emoji: data.emoji,
          },
        });
      }
      return right(undefined);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao registrar reação')); }
  }

  async deleteReaction(reactionId: string): RepositoryResponse<void> {
    try {
      await this.prisma.messageReaction.delete({ where: { id: reactionId } });
      return right(undefined);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao remover reação')); }
  }

  async getReactionsForMessage(messageId: string, model: ChatThreadType): RepositoryResponse<{ emoji: string; userId: string }[]> {
    try {
      const where = model === 'DIRECT'
        ? { directMessageId: messageId }
        : { chatMessageId: messageId };
      const reactions = await this.prisma.messageReaction.findMany({ where, select: { emoji: true, userId: true } });
      return right(reactions);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar reações')); }
  }

  async findDirectMessagesByType(
    conversationId: string,
    type: MessageType,
    limit: number,
    cursor?: string,
  ): RepositoryResponse<DirectMessageWithSender[]> {
    try {
      const result = await this.prisma.directMessage.findMany({
        where: { conversationId, type },
        orderBy: { createdAt: 'desc' },
        take: limit + 1,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        include: {
          sender: { select: USER_SELECT_MINIMAL },
          replyTo: { select: REPLY_TO_SELECT },
        },
      });
      return right(result as DirectMessageWithSender[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar mensagens'));
    }
  }

  async findChatMessagesByType(
    orderId: string,
    type: MessageType,
    limit: number,
    cursor?: string,
  ): RepositoryResponse<ChatMessageWithSender[]> {
    try {
      const result = await this.prisma.chatMessage.findMany({
        where: { orderId, type },
        orderBy: { createdAt: 'desc' },
        take: limit + 1,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        include: {
          sender: { select: USER_SELECT_MINIMAL },
          replyTo: { select: REPLY_TO_SELECT },
        },
      });
      return right(result as ChatMessageWithSender[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar mensagens'));
    }
  }

  async findReplyToSummary(id: string): RepositoryResponse<ReplyToSummary | null> {
    try {
      const directMsg = await this.prisma.directMessage.findUnique({
        where: { id },
        select: { ...REPLY_TO_SELECT, conversationId: true },
      });
      if (directMsg) return right(directMsg as ReplyToSummary);

      const chatMsg = await this.prisma.chatMessage.findUnique({
        where: { id },
        select: { ...REPLY_TO_SELECT, orderId: true },
      });
      if (chatMsg) return right({ ...chatMsg, conversationId: chatMsg.orderId } as ReplyToSummary);

      return right(null);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar mensagem referenciada'));
    }
  }
}
