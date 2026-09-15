import { Test, TestingModule } from '@nestjs/testing';
import { GetConversationsUseCase } from './get-conversations.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationsByUser: jest.fn(),
};

describe('GetConversationsUseCase', () => {
  let sut: GetConversationsUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetConversationsUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get(GetConversationsUseCase);
    jest.clearAllMocks();
  });

  it('returns empty list when no conversations', async () => {
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([]));
    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual([]);
  });

  it('returns conversations with correct otherUser', async () => {
    const now = new Date();
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE', createdAt: now, lastMessageAt: now,
        user1: { id: 'user-1', displayName: 'Me', avatarUrl: null, isVerified: true },
        user2: { id: 'user-2', displayName: 'Other', avatarUrl: null, isVerified: false },
        messages: [{ id: 'msg-1', content: 'Last msg', senderId: 'user-2', readAt: null, createdAt: now }],
      },
    ]));

    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].otherUser.displayName).toBe('Other');
      expect(result.value[0].unreadCount).toBe(1);
      expect(result.value[0].lastMessage?.content).toBe('Last msg');
    }
  });

  it('picks user1 as otherUser when user-1 is not a participant', async () => {
    const now = new Date();
    mockRepo.findDirectConversationsByUser.mockResolvedValue(right([
      {
        id: 'conv-2', user1Id: 'user-2', user2Id: 'user-3', status: 'PENDING', createdAt: now, lastMessageAt: now,
        user1: { id: 'user-2', displayName: 'User2', avatarUrl: null, isVerified: false },
        user2: { id: 'user-3', displayName: 'User3', avatarUrl: null, isVerified: false },
        messages: [],
      },
    ]));

    const result = await sut.execute('user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value[0].otherUser.displayName).toBe('User2');
    }
  });
});
