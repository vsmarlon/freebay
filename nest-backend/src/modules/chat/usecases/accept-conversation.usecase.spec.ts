import { Test, TestingModule } from '@nestjs/testing';
import { AcceptConversationUseCase } from './accept-conversation.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationById: jest.fn(),
  updateDirectConversation: jest.fn(),
};

describe('AcceptConversationUseCase', () => {
  let sut: AcceptConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AcceptConversationUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get(AcceptConversationUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not a participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' }));
    const result = await sut.execute('conv-1', 'stranger');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error if conversation is not PENDING', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should accept conversation successfully', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'PENDING' }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({ id: 'conv-1', status: 'ACTIVE' }));

    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.accepted).toBe(true);
    expect(mockRepo.updateDirectConversation).toHaveBeenCalledWith('conv-1', { status: 'ACTIVE' });
  });
});
