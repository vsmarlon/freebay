import { Test, TestingModule } from '@nestjs/testing';
import { SendMessageUseCase } from './send-message.usecase';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationById: jest.fn(),
  createDirectMessage: jest.fn(),
  updateDirectConversation: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn().mockResolvedValue(right(false)),
};

const mockOgScraper = {
  extractFirstUrl: jest.fn().mockReturnValue(null),
  scrape: jest.fn(),
};

describe('SendMessageUseCase', () => {
  let sut: SendMessageUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SendMessageUseCase,
        { provide: ConversationRepository, useValue: mockRepo },
        { provide: BlockRepository, useValue: mockBlockRepository },
        { provide: OgScraperService, useValue: mockOgScraper },
      ],
    }).compile();

    sut = module.get<SendMessageUseCase>(SendMessageUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if conversation is pending and user not participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' }));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    const result = await sut.execute({ senderId: 'stranger', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should send message successfully in active conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hello', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.content).toBe('Hello');
      expect(result.value.conversationId).toBe('conv-1');
    }
  });

  it('should allow participant to send in pending conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'PENDING' }));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hi', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hi' });
    expect(result.isRight()).toBe(true);
  });
});
