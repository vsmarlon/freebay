import { Test, TestingModule } from '@nestjs/testing';
import { StartConversationUseCase } from './start-conversation.usecase';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findUserById: jest.fn().mockResolvedValue(right({ id: 'user-2', displayName: 'Jane' })),
  findDirectConversationBetweenUsers: jest.fn(),
  createDirectConversation: jest.fn(),
  findFollow: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn().mockResolvedValue(false),
};

describe('StartConversationUseCase', () => {
  let sut: StartConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StartConversationUseCase,
        { provide: ConversationRepository, useValue: mockRepo },
        { provide: BlockRepository, useValue: mockBlockRepository },
      ],
    }).compile();

    sut = module.get<StartConversationUseCase>(StartConversationUseCase);
    jest.clearAllMocks();
  });

  it('should return error if starting conversation with self', async () => {
    const result = await sut.execute('user-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return existing conversation if one exists', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right({ id: 'conv-1', status: 'ACTIVE' }));
    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.conversationId).toBe('conv-1');
      expect(result.value.status).toBe('ACTIVE');
    }
  });

  it('should create ACTIVE conversation if following', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right({ id: 'follow-1' }));
    mockRepo.createDirectConversation.mockResolvedValue(right({ id: 'conv-2', status: 'ACTIVE' }));

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('ACTIVE');
    }
  });

  it('should create PENDING conversation if not following', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right(null));
    mockRepo.createDirectConversation.mockResolvedValue(right({ id: 'conv-3', status: 'PENDING' }));

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('PENDING');
    }
  });
});
