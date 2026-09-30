import { Prisma, DirectConversation, User, ConversationPreference, ChatThreadType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import {
  DirectConversationWithDetails,
  OrderWithChatRecord,
  ProductConversationSummaryRecord,
  productConversationSummaryValidator,
} from './payloads';
import { ConversationStartRecord, toProductConversationSummary } from '../../../dtos/conversation-response';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';

export function findUserById(prisma: PrismaService, id: string): Promise<User | null> {
  return prisma.user.findUnique({ where: { id } });
}

export function findFollow(prisma: PrismaService, followerId: string, followingId: string): Promise<{ id: string } | null> {
  return prisma.follow.findFirst({ where: { followerId, followingId }, select: { id: true } });
}

export function findDirectConversationById(prisma: PrismaService, id: string): Promise<DirectConversation | null> {
  return prisma.directConversation.findUnique({ where: { id } });
}

export async function findDirectConversationsByUser(prisma: PrismaService, userId: string): Promise<DirectConversationWithDetails[]> {
  const conversations = await prisma.directConversation.findMany({
    where: { OR: [{ user1Id: userId }, { user2Id: userId }] },
    include: {
      user1: { select: USER_SELECT_BASIC },
      user2: { select: USER_SELECT_BASIC },
      product: { select: productConversationSummaryValidator.select },
      messages: {
        take: 1,
        select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
        orderBy: { createdAt: 'desc' },
      },
      _count: { select: { messages: { where: { senderId: { not: userId }, readAt: null } } } },
    },
    orderBy: { lastMessageAt: 'desc' },
  });
  return conversations;
}

export function findDirectConversationBetweenUsers(
  prisma: PrismaService,
  user1Id: string,
  user2Id: string,
  scopeKey = 'DIRECT',
): Promise<ConversationStartRecord | null> {
  return prisma.directConversation.findFirst({
    where: {
      user1Id: user1Id < user2Id ? user1Id : user2Id,
      user2Id: user1Id < user2Id ? user2Id : user1Id,
      scopeKey,
    },
    include: { product: { select: productConversationSummaryValidator.select } },
  }).then((conversation) => conversation ? {
    conversationId: conversation.id,
    status: conversation.status,
    threadType: ChatThreadType.DIRECT,
    product: conversation.product ? toProductConversationSummary(conversation.product) : null,
  } : null);
}

export function findProductSummary(prisma: PrismaService, productId: string): Promise<ProductConversationSummaryRecord | null> {
  return prisma.product.findUnique({ where: { id: productId }, ...productConversationSummaryValidator });
}

export async function createDirectConversation(
  prisma: PrismaService,
  data: Prisma.DirectConversationCreateInput,
): RepositoryResponse<ConversationStartRecord> {
  try {
    const conversation = await prisma.directConversation.create({
      data,
      include: { product: { select: productConversationSummaryValidator.select } },
    });
    return right({
      conversationId: conversation.id,
      status: conversation.status,
      threadType: ChatThreadType.DIRECT,
      product: conversation.product ? toProductConversationSummary(conversation.product) : null,
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const user1Id = data.user1?.connect?.id;
      const user2Id = data.user2?.connect?.id;
      const scopeKey = data.scopeKey;
      if (user1Id && user2Id && typeof scopeKey === 'string') {
        try {
          const reread = await findDirectConversationBetweenUsers(prisma, user1Id, user2Id, scopeKey);
          if (reread) return right(reread);
        } catch {
          // The original repository treated a failed reconciliation as a database failure.
        }
      }
    }
    return left(new DatabaseError('Erro ao criar conversa'));
  }
}

export function updateDirectConversation(
  prisma: PrismaService,
  id: string,
  data: Prisma.DirectConversationUpdateInput,
): Promise<DirectConversation> {
  return prisma.directConversation.update({ where: { id }, data });
}

export function findOrdersByUser(prisma: PrismaService, userId: string): Promise<OrderWithChatRecord[]> {
  return prisma.order.findMany({
    where: { OR: [{ buyerId: userId }, { sellerId: userId }] },
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
}

export async function countUnreadChatMessages(prisma: PrismaService, orderIds: string[], userId: string): Promise<Record<string, number>> {
  if (orderIds.length === 0) return {};
  const grouped = await prisma.chatMessage.groupBy({
    by: ['orderId'],
    where: { orderId: { in: orderIds }, senderId: { not: userId }, readAt: null },
    _count: { id: true },
  });
  const map: Record<string, number> = {};
  for (const group of grouped) map[group.orderId] = group._count.id;
  return map;
}

export function findPreferencesByUser(prisma: PrismaService, userId: string): Promise<ConversationPreference[]> {
  return prisma.conversationPreference.findMany({ where: { userId, isDeleted: false } });
}
