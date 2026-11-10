import { describe, expect, it } from 'vitest';
import type { Conversation } from './model';
import { groupConversationsByCounterparty } from './inbox-grouping';

const conversation = (id: string, counterpart: string, unreadCount = 0): Conversation => ({
  id,
  threadType: 'DIRECT',
  otherUser: { id: counterpart, displayName: counterpart, avatarUrl: null },
  lastMessage: null,
  unreadCount,
  status: 'ACCEPTED',
  createdAt: '2026-10-09T00:00:00.000Z',
  product: { id: `product-${id}`, title: `Product ${id}`, imageUrl: null, status: 'ACTIVE' },
});

describe('inbox counterpart folders', () => {
  it('groups by counterpart identity and keeps product threads as separate ordered rows', () => {
    const items = [
      conversation('first', 'seller-a', 2),
      conversation('second', 'seller-a'),
      conversation('third', 'seller-b'),
    ];

    const groups = groupConversationsByCounterparty(items);

    expect([...groups.keys()]).toEqual(['seller-a', 'seller-b']);
    expect(groups.get('seller-a')?.map((item) => item.id)).toEqual(['first', 'second']);
    expect(groups.get('seller-a')?.map((item) => item.product?.id)).toEqual([
      'product-first',
      'product-second',
    ]);
    expect(groups.get('seller-a')?.[0].unreadCount).toBe(2);
    expect(groups.get('seller-b')?.map((item) => item.id)).toEqual(['third']);
  });
});
