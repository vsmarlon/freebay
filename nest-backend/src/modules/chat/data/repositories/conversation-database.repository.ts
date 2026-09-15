import { Injectable } from '@nestjs/common';
import { Prisma, DirectConversation, User, DirectMessage, ChatMessage, ChatThreadType, ConversationPreference, MessageReaction, MessageType, StarredMessage } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse, right, left } from '@/shared/core/either';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { DatabaseError } from '@/shared/core/errors';
import { USER_SELECT_BASIC, USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { deleteUpload } from '@/shared/utils/file.utils';
import {
  DirectConversationWithDetails,
  OrderWithChatRecord,
  DirectMessageWithSender,
  ChatMessageWithSender,
  ReplyToSummary,
  ProductConversationSummaryRecord,
  productConversationSummaryValidator,
  ConversationStartRecord,
  toProductConversationSummary,
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
export class ConversationDatabaseRepository extends BasePrismaRepository {
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
          product: { select: productConversationSummaryValidator.select },
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

  async findDirectConversationBetweenUsers(user1Id: string, user2Id: string, scopeKey = 'DIRECT'): RepositoryResponse<ConversationStartRecord | null> {
    return this.safeRun(
      () =>
        this.prisma.directConversation.findFirst({
          where: {
            user1Id: user1Id < user2Id ? user1Id : user2Id,
            user2Id: user1Id < user2Id ? user2Id : user1Id,
            scopeKey,
          },
          include: { product: { select: productConversationSummaryValidator.select } },
        }).then((conversation) => conversation ? {
          conversationId: conversation.id,
          status: conversation.status,
          threadType: 'DIRECT' as const,
          product: conversation.product ? toProductConversationSummary(conversation.product) : null,
        } : null),
      'Erro ao buscar conversa',
    );
  }

  async findProductConversationBetweenUsers(user1Id: string, user2Id: string, productId: string): RepositoryResponse<ConversationStartRecord | null> {
    return this.findDirectConversationBetweenUsers(user1Id, user2Id, `PRODUCT:${productId}`);
  }

  async findProductSummary(productId: string): RepositoryResponse<ProductConversationSummaryRecord | null> {
    return this.safeRun(
      () => this.prisma.product.findUnique({ where: { id: productId }, ...productConversationSummaryValidator }),
      'Erro ao buscar produto',
    );
  }

  async createDirectConversation(data: Prisma.DirectConversationCreateInput): RepositoryResponse<ConversationStartRecord> {
    try {
      const conversation = await this.prisma.directConversation.create({
        data,
        include: { product: { select: productConversationSummaryValidator.select } },
      });
      return right({
        conversationId: conversation.id,
        status: conversation.status,
        threadType: 'DIRECT',
        product: conversation.product ? toProductConversationSummary(conversation.product) : null,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const user1Id = data.user1?.connect?.id;
        const user2Id = data.user2?.connect?.id;
        const scopeKey = data.scopeKey;
        if (user1Id && user2Id && typeof scopeKey === 'string') {
          const reread = await this.findDirectConversationBetweenUsers(user1Id, user2Id, scopeKey);
      if (reread.isRight() && reread.value) return right(reread.value);
        }
      }
      return left(new DatabaseError('Erro ao criar conversa'));
    }
  }

  async updateDirectConversation(id: string, data: Prisma.DirectConversationUpdateInput): RepositoryResponse<DirectConversation> {
    return this.safeRun(
      () => this.prisma.directConversation.update({ where: { id }, data }),
      'Erro ao atualizar conversa',
    );
  }

  async findDirectMessageByClientId(
    conversationId: string,
    senderId: string,
    clientMessageId: string,
  ): RepositoryResponse<DirectMessage | null> {
    return this.safeRun(
      () => this.prisma.directMessage.findFirst({
        where: { conversationId, senderId, clientMessageId },
      }),
      'Erro ao buscar mensagem existente',
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
        conversationId &&
        data.sender.connect?.id
      ) {
        const existing = await this.prisma.directMessage.findFirst({
          where: {
            conversationId,
            senderId: data.sender.connect.id,
            clientMessageId: data.clientMessageId,
          },
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
        orderId &&
        data.sender.connect?.id
      ) {
        const existing = await this.prisma.chatMessage.findFirst({
          where: {
            orderId,
            senderId: data.sender.connect.id,
            clientMessageId: data.clientMessageId,
          },
          include: query.include,
        });
        if (existing) return right(existing as ChatMessage | ChatMessageWithSender);
      }
      return left(new DatabaseError('Erro ao criar mensagem'));
    }
  }

  async findChatMessageByClientId(
    orderId: string,
    senderId: string,
    clientMessageId: string,
  ): RepositoryResponse<ChatMessage | null> {
    return this.safeRun(
      () => this.prisma.chatMessage.findFirst({
        where: { orderId, senderId, clientMessageId },
      }),
      'Erro ao buscar mensagem existente',
    );
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
        const deleted = await this.prisma.directMessage.update({
          where: { id },
          data: { deletedAt: new Date() },
          select: { attachmentUrl: true },
        });
        deleteUpload(deleted.attachmentUrl);
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

  async findStarByUserAndMessage(userId: string, messageId: string, model: ChatThreadType): RepositoryResponse<StarredMessage | null> {
    return this.safeRun(async () => {
      const where = model === 'DIRECT'
        ? { userId, directMessageId: messageId }
        : { userId, chatMessageId: messageId };
      return this.prisma.starredMessage.findFirst({ where });
    }, 'Erro ao buscar favorita');
  }

  async createStar(data: { userId: string; messageId: string; model: ChatThreadType }): RepositoryResponse<void> {
    return this.safeRun(async () => {
      const msgField = data.model === 'DIRECT' ? 'directMessageId' : 'chatMessageId';
      await this.prisma.starredMessage.create({
        data: { userId: data.userId, [msgField]: data.messageId },
      });
    }, 'Erro ao favoritar mensagem');
  }

  async deleteStar(starId: string): RepositoryResponse<void> {
    return this.safeRun(
      async () => {
        await this.prisma.starredMessage.delete({ where: { id: starId } });
      },
      'Erro ao desfavoritar mensagem',
    );
  }

  async findStarredMessages(
    userId: string,
    threadId: string,
    model: ChatThreadType,
  ): RepositoryResponse<(DirectMessageWithSender | ChatMessageWithSender)[]> {
    return this.safeRun(async () => {
      const stars = await this.prisma.starredMessage.findMany({
        where: {
          userId,
          ...(model === 'DIRECT'
            ? { directMessage: { conversationId: threadId } }
            : { chatMessage: { orderId: threadId } }),
        },
        select: { directMessageId: true, chatMessageId: true },
        orderBy: { createdAt: 'desc' },
      });
      const ids = stars
        .map((s) => s.directMessageId ?? s.chatMessageId)
        .filter((id): id is string => id != null);
      if (ids.length === 0) return [];
      const include = {
        sender: { select: USER_SELECT_MINIMAL },
        replyTo: { select: REPLY_TO_SELECT },
      };
      if (model === 'DIRECT') {
        return this.prisma.directMessage.findMany({
          where: { id: { in: ids } },
          include,
        }) as Promise<DirectMessageWithSender[]>;
      }
      return this.prisma.chatMessage.findMany({
        where: { id: { in: ids } },
        include,
      }) as Promise<ChatMessageWithSender[]>;
    }, 'Erro ao buscar favoritas');
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

  async messageBelongsToThread(
    messageId: string,
    threadId: string,
    model: ChatThreadType,
  ): RepositoryResponse<boolean> {
    return this.safeRun(async () => {
      if (model === ChatThreadType.ORDER) {
        const found = await this.prisma.chatMessage.findFirst({
          where: { id: messageId, orderId: threadId },
          select: { id: true },
        });
        return found !== null;
      }

      const found = await this.prisma.directMessage.findFirst({
        where: { id: messageId, conversationId: threadId },
        select: { id: true },
      });
      return found !== null;
    }, 'Erro ao verificar mensagem da conversa');
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
