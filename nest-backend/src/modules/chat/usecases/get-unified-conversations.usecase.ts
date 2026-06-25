import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';
import { ConversationMapper, UnifiedConversationResponse } from '../mappers/conversation.mapper';

@Injectable()
export class GetUnifiedConversationsUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(
    userId: string,
    query?: string,
    archived?: boolean,
  ): Promise<Either<AppError, UnifiedConversationResponse[]>> {
    const [directConvs, orderConvs, preferences] = await Promise.all([
      this.fetchDirectConversations(userId),
      this.fetchOrderConversations(userId),
      this.prisma.conversationPreference.findMany({
        where: { userId, isDeleted: false },
      }),
    ]);

    const prefMap = new Map<string, (typeof preferences)[0]>();
    for (const p of preferences) {
      const key = p.directConversationId ?? p.orderId;
      if (key) prefMap.set(key, p);
    }

    const filterDeleted = (id: string) => {
      const pref = prefMap.get(id);
      return !pref?.isDeleted;
    };

    const filterArchived = (id: string, onlyArchived: boolean) => {
      const pref = prefMap.get(id);
      return onlyArchived ? pref?.isArchived === true : !pref?.isArchived;
    };

    const mappedDirect = directConvs
      .filter(c => filterDeleted(c.id) && filterArchived(c.id, !!archived))
      .map(c => ConversationMapper.toUnifiedDirect(c, userId, prefMap.get(c.id) ?? null));

    const mappedOrders = orderConvs
      .filter(o => filterDeleted(o.id) && filterArchived(o.id, !!archived))
      .map(o => ConversationMapper.toUnifiedOrder(o, userId, prefMap.get(o.id) ?? null));

    let all = [...mappedDirect, ...mappedOrders];

    if (query) {
      const q = query.toLowerCase();
      all = all.filter(c => {
        const nameMatch = c.otherUser.displayName.toLowerCase().includes(q);
        const msgMatch = c.lastMessage?.content?.toLowerCase().includes(q);
        return nameMatch || msgMatch;
      });
    }

    all.sort((a, b) => {
      const aTime = a.lastMessage?.createdAt ?? a.createdAt;
      const bTime = b.lastMessage?.createdAt ?? b.createdAt;
      return bTime.localeCompare(aTime);
    });

    return right(all);
  }

  private fetchDirectConversations(userId: string) {
    return this.prisma.directConversation.findMany({
      where: { OR: [{ user1Id: userId }, { user2Id: userId }] },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        user1: { select: USER_SELECT_BASIC },
        user2: { select: USER_SELECT_BASIC },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
        },
      },
    });
  }

  private fetchOrderConversations(userId: string) {
    return this.prisma.order.findMany({
      where: { OR: [{ buyerId: userId }, { sellerId: userId }] },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        buyerId: true,
        sellerId: true,
        status: true,
        createdAt: true,
        product: { select: { id: true, title: true } },
        buyer: { select: USER_SELECT_BASIC },
        seller: { select: USER_SELECT_BASIC },
        chatMessages: {
          orderBy: { createdAt: 'asc' },
          select: { id: true, content: true, senderId: true, createdAt: true, readAt: true },
        },
      },
    });
  }
}
