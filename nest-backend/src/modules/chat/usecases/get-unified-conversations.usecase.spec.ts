import { Test, TestingModule } from '@nestjs/testing';
import { GetUnifiedConversationsUseCase } from './get-unified-conversations.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationsByUser: jest.fn(),
  findOrdersByUser: jest.fn(),
  countUnreadChatMessages: jest.fn(),
  findPreferencesByUser: jest.fn(),
};

describe('GetUnifiedConversationsUseCase', () => {
  let sut: GetUnifiedConversationsUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetUnifiedConversationsUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get(GetUnifiedConversationsUseCase);
    jest.clearAllMocks();
    mockRepo.countUnreadChatMessages.mockResolvedValue(right({}));
  });

  it('returns empty array when user has no conversations', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toEqual([]);
      expect(result.value.hasMore).toBe(false);
      expect(result.value.nextCursor).toBeNull();
    }
  });

  it('returns direct conversations mapped correctly', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'dc-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        status: 'ACTIVE',
        lastMessageAt: new Date('2026-06-24'),
        createdAt: new Date('2026-06-20'),
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        user2: { id: 'user-2', displayName: 'Alice', avatarUrl: null, isVerified: true },
        messages: [
          { id: 'm-1', content: 'Hi', senderId: 'user-2', createdAt: new Date('2026-06-24'), readAt: null },
        ],
      },
    ]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toHaveLength(1);
      expect(result.value.items[0].id).toBe('dc-1');
      expect(result.value.items[0].threadType).toBe('DIRECT');
      expect(result.value.items[0].otherUser.displayName).toBe('Alice');
    }
  });

  it('returns order conversations mapped correctly', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([
      {
        id: 'order-1',
        buyerId: 'user-1',
        sellerId: 'user-2',
        status: 'COMPLETED',
        createdAt: new Date('2026-06-22'),
        product: { id: 'prod-1', title: 'Camera' },
        buyer: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        seller: { id: 'user-2', displayName: 'Bob', avatarUrl: null, isVerified: true },
        chatMessages: [
          { id: 'cm-1', content: 'Thanks!', senderId: 'user-2', createdAt: new Date('2026-06-23'), readAt: null },
        ],
        unreadCount: 0,
      },
    ]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toHaveLength(1);
      expect(result.value.items[0].id).toBe('order-1');
      expect(result.value.items[0].threadType).toBe('ORDER');
      expect(result.value.items[0].otherUser.displayName).toBe('Me');
    }
  });

  it('returns both direct and order conversations', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'dc-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        status: 'ACTIVE',
        lastMessageAt: new Date('2026-06-20'),
        createdAt: new Date('2026-06-20'),
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        user2: { id: 'user-2', displayName: 'Alice', avatarUrl: null, isVerified: true },
        messages: [],
      },
    ]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([
      {
        id: 'order-1',
        buyerId: 'user-1',
        sellerId: 'user-3',
        status: 'ACTIVE',
        createdAt: new Date('2026-06-22'),
        product: { id: 'prod-1', title: 'Camera' },
        buyer: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        seller: { id: 'user-3', displayName: 'Bob', avatarUrl: null, isVerified: true },
        chatMessages: [],
        unreadCount: 0,
      },
    ]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.items).toHaveLength(2);
  });

  it('filters by archived flag', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'dc-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        status: 'ACTIVE',
        lastMessageAt: new Date('2026-06-20'),
        createdAt: new Date('2026-06-20'),
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        user2: { id: 'user-2', displayName: 'Alice', avatarUrl: null, isVerified: true },
        messages: [],
      },
    ]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([
      { id: 'pref-1', userId: 'user-1', directConversationId: 'dc-1', orderId: null, isArchived: true, isDeleted: false },
    ]));

    const normal = await sut.execute('user-1');
    expect(normal.isRight()).toBe(true);
    if (normal.isRight()) expect(normal.value.items).toHaveLength(0);

    const archived = await sut.execute('user-1', undefined, true);
    expect(archived.isRight()).toBe(true);
    if (archived.isRight()) expect(archived.value.items).toHaveLength(1);
  });

  it('filters by search query', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'dc-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        status: 'ACTIVE',
        lastMessageAt: new Date('2026-06-20'),
        createdAt: new Date('2026-06-20'),
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        user2: { id: 'user-2', displayName: 'Alice', avatarUrl: null, isVerified: true },
        messages: [
          { id: 'm-1', content: 'See you tomorrow', senderId: 'user-2', createdAt: new Date('2026-06-20'), readAt: null },
        ],
      },
      {
        id: 'dc-2',
        user1Id: 'user-1',
        user2Id: 'user-3',
        status: 'ACTIVE',
        lastMessageAt: new Date('2026-06-19'),
        createdAt: new Date('2026-06-19'),
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
        user2: { id: 'user-3', displayName: 'Bob', avatarUrl: null, isVerified: true },
        messages: [
          { id: 'm-2', content: 'Deal!', senderId: 'user-3', createdAt: new Date('2026-06-19'), readAt: null },
        ],
      },
    ]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-1', 'ali');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toHaveLength(1);
      expect(result.value.items[0].otherUser.displayName).toBe('Alice');
    }

    const result2 = await sut.execute('user-1', 'tomorrow');
    expect(result2.isRight()).toBe(true);
    if (result2.isRight()) {
      expect(result2.value.items).toHaveLength(1);
      expect(result2.value.items[0].otherUser.displayName).toBe('Alice');
    }
  });

  it('paginates with opaque offset cursors', async () => {
    const convos = Array.from({ length: 25 }, (_, i) => ({
      id: `dc-${i}`,
      user1Id: 'user-1',
      user2Id: `user-${i + 2}`,
      status: 'ACTIVE',
      lastMessageAt: new Date(Date.UTC(2026, 5, 20 + (i % 9), i % 24)),
      createdAt: new Date('2026-06-01'),
      user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: false },
      user2: { id: `user-${i + 2}`, displayName: `User ${i}`, avatarUrl: null, isVerified: false },
      messages: [],
    }));
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right(convos));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const page1 = await sut.execute('user-1', undefined, false, { limit: 20 });
    expect(page1.isRight()).toBe(true);
    if (page1.isRight()) {
      expect(page1.value.items).toHaveLength(20);
      expect(page1.value.hasMore).toBe(true);
      expect(page1.value.nextCursor).not.toBeNull();

      const page2 = await sut.execute('user-1', undefined, false, {
        limit: 20,
        cursor: page1.value.nextCursor ?? undefined,
      });
      expect(page2.isRight()).toBe(true);
      if (page2.isRight()) {
        expect(page2.value.items).toHaveLength(5);
        expect(page2.value.hasMore).toBe(false);
        expect(page2.value.nextCursor).toBeNull();
        const ids1 = new Set(page1.value.items.map(c => c.id));
        for (const c of page2.value.items) expect(ids1.has(c.id)).toBe(false);
      }
    }
  });

  it('falls back to the first page on a malformed cursor', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([]));
    mockRepo.findOrdersByUser.mockResolvedValue(right([]));
    mockRepo.findPreferencesByUser.mockResolvedValue(right([]));

    const result = await sut.execute('user-1', undefined, false, { cursor: '!!!' });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.items).toEqual([]);
  });
});
