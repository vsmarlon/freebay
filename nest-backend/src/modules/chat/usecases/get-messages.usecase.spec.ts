import { Test, TestingModule } from '@nestjs/testing';
import { GetMessagesUseCase } from './get-messages.usecase';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationById: jest.fn(),
  findMessagesByConversation: jest.fn(),
  markMessagesRead: jest.fn().mockResolvedValue(right(undefined)),
};

describe('GetMessagesUseCase', () => {
  let sut: GetMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetMessagesUseCase,
        { provide: ConversationRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get<GetMessagesUseCase>(GetMessagesUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not a participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'a', user2Id: 'b' }));
    const result = await sut.execute('conv-1', 'stranger');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return messages and mark unread as read', async () => {
    const now = new Date();
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2' }));
    mockRepo.findMessagesByConversation.mockResolvedValue(right([
      { id: 'msg-1', conversationId: 'conv-1', senderId: 'user-2', content: 'Hello', type: 'TEXT', readAt: null, createdAt: now, sender: { id: 'user-2', displayName: 'Other', avatarUrl: null } },
    ]));

    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].content).toBe('Hello');
    }
  });
});
