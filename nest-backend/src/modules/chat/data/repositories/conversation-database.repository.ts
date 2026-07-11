import { Injectable } from '@nestjs/common';
import { Prisma, DirectConversation, User, DirectMessage, ConversationPreference } from '@prisma/client';
import { PrismaClient } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationRepository } from '../../domain/repositories/conversation.repository';
import { USER_SELECT_BASIC, USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import {
  DirectConversationWithDetails,
  OrderWithChat,
  DirectMessageWithSender,
} from '../../mappers/conversation.mapper';

@Injectable()
export class ConversationDatabaseRepository implements ConversationRepository {
  constructor(private readonly prisma: PrismaClient) {}

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
            select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
            orderBy: { createdAt: 'desc' },
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
        include: { sender: { select: USER_SELECT_MINIMAL } },
      }) as DirectMessageWithSender[]);
    } catch { return left(new AppError('DB_ERROR', 'Erro ao buscar mensagens')); }
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

  async findOrdersByUser(userId: string): RepositoryResponse<OrderWithChat[]> {
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
          product: { select: { id: true, title: true, images: { take: 1, orderBy: { order: 'asc' } } } },
        },
        orderBy: { updatedAt: 'desc' },
      });
      return right(orders as unknown as OrderWithChat[]);
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
}
