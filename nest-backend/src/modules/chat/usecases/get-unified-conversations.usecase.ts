import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import {
  CursorPage,
  buildOffsetCursorPage,
  clampLimit,
  decodeOffsetCursor,
} from '@/shared/core/pagination';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ConversationMapper, UnifiedConversationResponse } from '../mappers/conversation.mapper';

@Injectable()
export class GetUnifiedConversationsUseCase {
  constructor(private readonly conversationRepository: ConversationDatabaseRepository) {}

  async execute(
    userId: string,
    query?: string,
    archived?: boolean,
    rawPage: { cursor?: string; limit?: number } = {},
  ): Promise<Either<AppError, CursorPage<UnifiedConversationResponse>>> {
    const [directConvsResult, orderConvsResult, preferencesResult] = await Promise.all([
      this.conversationRepository.findDirectConversationsByUser(userId),
      this.conversationRepository.findOrdersByUser(userId),
      this.conversationRepository.findPreferencesByUser(userId),
    ]);

    if (directConvsResult.isLeft()) return left(directConvsResult.value);
    if (orderConvsResult.isLeft()) return left(orderConvsResult.value);
    if (preferencesResult.isLeft()) return left(preferencesResult.value);

    const directConvs = directConvsResult.value;
    const orderConvsData = orderConvsResult.value;
    const preferences = preferencesResult.value;

    const unreadResult = await this.conversationRepository.countUnreadChatMessages(
      orderConvsData.map(o => o.id), userId,
    );
    if (unreadResult.isLeft()) return left(unreadResult.value);

    const unreadMap = unreadResult.value;
    const orderConvs = orderConvsData.map(o => ({
      ...o,
      unreadCount: unreadMap[o.id] ?? 0,
    }));

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

    const limit = clampLimit(rawPage.limit);
    const offset = decodeOffsetCursor(rawPage.cursor);
    return right(
      buildOffsetCursorPage(all.slice(offset, offset + limit), offset, limit, all.length),
    );
  }
}
