import { Test, TestingModule } from '@nestjs/testing';
import { SendMessageUseCase } from './send-message.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationById: jest.fn(),
  createDirectMessage: jest.fn(),
  updateDirectConversation: jest.fn(),
  createChatMessage: jest.fn(),
  messageBelongsToThread: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn(),
};

const mockOgScraper = {
  extractFirstUrl: jest.fn(),
  scrape: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

describe('SendMessageUseCase', () => {
  let sut: SendMessageUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SendMessageUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: PrismaBlockRepository, useValue: mockBlockRepository },
        { provide: OgScraperService, useValue: mockOgScraper },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(SendMessageUseCase);
    jest.clearAllMocks();
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    mockOgScraper.extractFirstUrl.mockReturnValue(null);
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.messageBelongsToThread.mockResolvedValue(right(true));
  });

  it('should return error if thread cannot be resolved', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if conversation is pending and user not participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' }));

    const result = await sut.execute({ senderId: 'stranger', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should send message successfully in active conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
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
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hi', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hi' });

    expect(result.isRight()).toBe(true);
  });

  it('should persist the replyToId relation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-2', conversationId: 'conv-1', senderId: 'user-1', content: 'Resposta', type: 'TEXT', replyToId: 'msg-1', createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Resposta', replyToId: 'msg-1' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.replyToId).toBe('msg-1');
    expect(mockRepo.createDirectMessage).toHaveBeenCalledWith(
      expect.objectContaining({ replyTo: { connect: { id: 'msg-1' } } }),
      true,
    );
  });

  it('should write to ChatMessage for order threads', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1', orderStatus: 'CONFIRMED' }),
    );
    mockRepo.createChatMessage.mockResolvedValue(right({
      id: 'msg-1', senderId: 'buyer-1', content: 'Chegou?', type: 'TEXT', replyToId: null, createdAt: new Date(),
    }));

    const result = await sut.execute({ senderId: 'buyer-1', conversationId: 'order-1', content: 'Chegou?' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.conversationId).toBe('order-1');
    expect(mockRepo.createChatMessage).toHaveBeenCalled();
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });

  it('rejects a reply that targets a message from another conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    mockRepo.messageBelongsToThread.mockResolvedValue(right(false));

    const result = await sut.execute({
      senderId: 'user-1',
      conversationId: 'conv-1',
      content: 'Resposta',
      replyToId: 'msg-from-elsewhere',
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });
});
