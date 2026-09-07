import { Injectable } from '@nestjs/common';
import { Prisma, DirectConversation, User, DirectMessage, ChatMessage, ChatThreadType, ConversationPreference, MessageReaction, MessageType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse, right, left } from '@/shared/core/either';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { DatabaseError } from '@/shared/core/errors';
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
export class ConversationDatabaseRepository extends BasePrismaRepository implements ConversationRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findUserById(id: string): RepositoryResponse<User | null> {
    return this.safeRun(
      () => this.prisma.user.findUnique({ where: { id } }),
      'Erro ao buscar usuário',
    );
  }

  async findFollow(followerId: string, followingId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(
      () =>
        this.prisma.follow.findFirst({
          where: { followerId, followingId },
          select: { id: true },
        }),
      'Erro ao buscar relacionamento',
    );
  }

  async findDirectConversationById(id: string): RepositoryResponse<DirectConversation | null> {
    return this.safeRun(
      () => this.prisma.directConversation.findUnique({ where: { id } }),
      'Erro ao buscar conversa',
    );
  }

  async findDirectConversationsByUser(userId: string): RepositoryResponse<DirectConversationWithDetails[]> {
    return this.safeRun(async () => {
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
      return convs as DirectConversationWithDetails[];
    }, 'Erro ao buscar conversas');
  }

  async findDirectConversationBetweenUsers(user1Id: string, user2Id: string): RepositoryResponse<DirectConversation | null> {
    return this.safeRun(
      () =>
        this.prisma.directConversation.findFirst({
          where: {
            OR: [
              { user1Id, user2Id },
              { user1Id: user2Id, user2Id: user1Id },
            ],
          },
        }),
      'Erro ao buscar conversa',
    );
  }

  async createDirectConversation(data: Prisma.DirectConversationCreateInput): RepositoryResponse<DirectConversation> {
    return this.safeRun(
      () => this.prisma.directConversation.create({ data }),
      'Erro ao criar conversa',
    );
  }

  async updateDirectConversation(id: string, data: Prisma.DirectConversationUpdateInput): RepositoryResponse<DirectConversation> {
    return this.safeRun(
      () => this.prisma.directConversation.update({ where: { id }, data }),
      'Erro ao atualizar conversa',
    );
  }

  async createDirectMessage(data: Prisma.DirectMessageCreateInput, includeSender?: boolean): RepositoryResponse<DirectMessage | DirectMessageWithSender> {
    const query: Prisma.DirectMessageCreateArgs = { data };
    if (includeSender) {
      query.include = { sender: { select: USER_SELECT_MINIMAL } };
    }
    try {
      const msg = await this.prisma.directMessage.create(query);
      return right(msg as DirectMessage | DirectMessageWithSender);
    } catch (e) {
      const conversationId = data.conversation.connect?.id;
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002' &&
        data.clientMessageId &&
        conversationId
      ) {
        const existing = await this.prisma.directMessage.findFirst({
          where: { conversationId, clientMessageId: data.clientMessageId },
          include: query.include,
        });
        if (existing) return right(existing as DirectMessage | DirectMessageWithSender);
      }
      return left(new DatabaseError('Erro ao criar mensagem'));
    }
  }

  async findMessagesByConversation(
    conversationId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<DirectMessageWithSender>> {
    return this.safeRun(
      () =>
        paginateById<DirectMessageWithSender, Prisma.DirectMessageFindManyArgs>(
          (args) =>
            this.prisma.directMessage.findMany(args) as Promise<DirectMessageWithSender[]>,
          {
            where: { conversationId },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            include: {
              sender: { select: USER_SELECT_MINIMAL },
              replyTo: { select: REPLY_TO_SELECT },
            },
          },
          page,
        ),
      'Erro ao buscar mensagens',
    );
  }

  async createChatMessage(data: Prisma.ChatMessageCreateInput, includeSender?: boolean): RepositoryResponse<ChatMessage | ChatMessageWithSender> {
    const query: Prisma.ChatMessageCreateArgs = { data };
    if (includeSender) {
      query.include = { sender: { select: USER_SELECT_MINIMAL } };
    }
    try {
      const msg = await this.prisma.chatMessage.create(query);
      return right(msg as ChatMessage | ChatMessageWithSender);
    } catch (e) {
      const orderId = data.order.connect?.id;
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002' &&
        data.clientMessageId &&
        orderId
      ) {
        const existing = await this.prisma.chatMessage.findFirst({
          where: { orderId, clientMessageId: data.clientMessageId },
          include: query.include,
        });
        if (existing) return right(existing as ChatMessage | ChatMessageWithSender);
      }
      return left(new DatabaseError('Erro ao criar mensagem'));
    }
  }

  async findChatMessagesByOrder(
    orderId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<ChatMessageWithSender>> {
    return this.safeRun(
      () =>
        paginateById<ChatMessageWithSender, Prisma.ChatMessageFindManyArgs>(
          (args) => this.prisma.chatMessage.findMany(args) as Promise<ChatMessageWithSender[]>,
          {
            where: { orderId },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            include: {
              sender: { select: USER_SELECT_MINIMAL },
              replyTo: { select: REPLY_TO_SELECT },
            },
          },
          page,
        ),
      'Erro ao buscar mensagens',
    );
  }

  async markChatMessagesRead(orderId: string, userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.chatMessage.updateMany({
        where: { orderId, senderId: { not: userId }, readAt: null },
        data: { readAt: new Date(), deliveredAt: new Date() },
      });
    }, 'Erro ao marcar mensagens');
  }

  async markMessagesDelivered(conversationId: string, userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.directMessage.updateMany({
        where: { conversationId, senderId: { not: userId }, deliveredAt: null },
        data: { deliveredAt: new Date() },
      });
    }, 'Erro ao marcar mensagens');
  }

  async markMessagesRead(conversationId: string, userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.directMessage.updateMany({
        where: { conversationId, senderId: { not: userId }, readAt: null },
        data: { readAt: new Date(), deliveredAt: new Date() },
      });
    }, 'Erro ao marcar mensagens');
  }

  async findOrdersByUser(userId: string): RepositoryResponse<OrderWithChatRecord[]> {
    return this.safeRun(
      () =>
        this.prisma.order.findMany({
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
        }),
      'Erro ao buscar pedidos',
    );
  }

  async countUnreadChatMessages(orderIds: string[], userId: string): RepositoryResponse<Record<string, number>> {
    return this.safeRun(async () => {
      if (orderIds.length === 0) return {};
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
      return map;
    }, 'Erro ao contar mensagens');
  }

  async findPreferencesByUser(userId: string): RepositoryResponse<ConversationPreference[]> {
    return this.safeRun(
      () =>
        this.prisma.conversationPreference.findMany({
          where: { userId, isDeleted: false },
        }),
      'Erro ao buscar preferências',
    );
  }

  async findDirectMessageById(id: string): RepositoryResponse<DirectMessage | null> {
    return this.safeRun(
      () => this.prisma.directMessage.findUnique({ where: { id } }),
      'Erro ao buscar mensagem',
    );
  }

  async softDeleteDirectMessage(id: string): RepositoryResponse<void> {
    return this.safeRun(
      async () => {
        await this.prisma.directMessage.update({ where: { id }, data: { deletedAt: new Date() } });
      },
      'Erro ao apagar mensagem',
    );
  }

  async findReactionByUserAndMessage(userId: string, messageId: string, model: ChatThreadType): RepositoryResponse<MessageReaction | null> {
    return this.safeRun(async () => {
      const where = model === 'DIRECT'
        ? { userId, directMessageId: messageId }
        : { userId, chatMessageId: messageId };
      return this.prisma.messageReaction.findFirst({ where });
    }, 'Erro ao buscar reação');
  }

  async upsertReaction(data: { userId: string; messageId: string; emoji: string; model: ChatThreadType }): RepositoryResponse<void> {
    return this.safeRun(async () => {
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
    }, 'Erro ao registrar reação');
  }

  async deleteReaction(reactionId: string): RepositoryResponse<void> {
    return this.safeRun(
      async () => {
        await this.prisma.messageReaction.delete({ where: { id: reactionId } });
      },
      'Erro ao remover reação',
    );
  }

  async getReactionsForMessage(messageId: string, model: ChatThreadType): RepositoryResponse<{ emoji: string; userId: string }[]> {
    return this.safeRun(async () => {
      const where = model === 'DIRECT'
        ? { directMessageId: messageId }
        : { chatMessageId: messageId };
      return this.prisma.messageReaction.findMany({ where, select: { emoji: true, userId: true } });
    }, 'Erro ao buscar reações');
  }

  async findDirectMessagesByType(
    conversationId: string,
    type: MessageType,
    limit: number,
    cursor?: string,
  ): RepositoryResponse<DirectMessageWithSender[]> {
    return this.safeRun(async () => {
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
      return result as DirectMessageWithSender[];
    }, 'Erro ao buscar mensagens');
  }

  async findChatMessagesByType(
    orderId: string,
    type: MessageType,
    limit: number,
    cursor?: string,
  ): RepositoryResponse<ChatMessageWithSender[]> {
    return this.safeRun(async () => {
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
      return result as ChatMessageWithSender[];
    }, 'Erro ao buscar mensagens');
  }

  async findReplyToSummary(id: string): RepositoryResponse<ReplyToSummary | null> {
    return this.safeRun(async () => {
      const directMsg = await this.prisma.directMessage.findUnique({
        where: { id },
        select: { ...REPLY_TO_SELECT, conversationId: true },
      });
      if (directMsg) return directMsg as ReplyToSummary;

      const chatMsg = await this.prisma.chatMessage.findUnique({
        where: { id },
        select: { ...REPLY_TO_SELECT, orderId: true },
      });
      if (chatMsg) return { ...chatMsg, conversationId: chatMsg.orderId } as ReplyToSummary;

      return null;
    }, 'Erro ao buscar mensagem referenciada');
  }
}
