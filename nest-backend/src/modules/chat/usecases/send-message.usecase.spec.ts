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
  findDirectMessageByClientId: jest.fn(),
  findChatMessageByClientId: jest.fn(),
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
    mockRepo.findDirectMessageByClientId.mockResolvedValue(right(null));
    mockRepo.findChatMessageByClientId.mockResolvedValue(right(null));
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.messageBelongsToThread.mockResolvedValue(right(true));
  });

  it('returns error if thread cannot be resolved', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if conversation is pending and user not participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' }));

    const result = await sut.execute({ senderId: 'stranger', conversationId: 'conv-1', content: 'Hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('sends message successfully in active conversation', async () => {
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

  it('sends a VIDEO message with an attachment', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-video', conversationId: 'conv-1', senderId: 'user-1', content: null,
      type: 'VIDEO', attachmentUrl: '/media/chat/video.mp4', createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({
      senderId: 'user-1',
      conversationId: 'conv-1',
      type: 'VIDEO',
      attachmentUrl: '/media/chat/video.mp4',
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectMessage).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'VIDEO', attachmentUrl: '/media/chat/video.mp4' }),
      true,
    );
  });

  it('allows participant to send in pending conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'PENDING' }));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hi', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hi' });

    expect(result.isRight()).toBe(true);
  });

  it('persists the replyToId relation', async () => {
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

  it('writes to ChatMessage for order threads', async () => {
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

  it('merges durationMs into metadata for AUDIO messages', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' }));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-audio', conversationId: 'conv-1', senderId: 'user-1', content: null,
      type: 'AUDIO', attachmentUrl: '/media/chat/audio.m4a',
      metadata: { durationMs: 12500 }, createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({
      senderId: 'user-1',
      conversationId: 'conv-1',
      type: 'AUDIO',
      attachmentUrl: '/media/chat/audio.m4a',
      durationMs: 12500,
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectMessage).toHaveBeenCalledWith(
      expect.objectContaining({ metadata: { durationMs: 12500 } }),
      true,
    );
  });

  it.each([
    { latitude: 91, longitude: 0 },
    { latitude: 0, longitude: -181 },
    { latitude: Number.NaN, longitude: 0 },
    { latitude: 0, longitude: 0, accuracyMeters: -1 },
    { latitude: 0, longitude: 0, accuracyMeters: 100001 },
    { latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt: 'not-a-date' },
    { latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt: '2026-09-14T05:00:00Z' },
    { latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt: new Date().toISOString(), address: 42 },
    { latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt: '2026-09-14T05:00:00.000Z', address: ' ' },
    { latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt: '2026-09-14T05:00:00.000Z', extra: true },
  ])('rejects invalid location metadata without persistence', async (metadata) => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));

    const result = await sut.execute({
      senderId: 'user-1',
      conversationId: 'conv-1',
      type: 'LOCATION',
      metadata,
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });

  it('persists canonical location metadata in a direct thread', async () => {
    const capturedAt = new Date().toISOString();
    const metadata = {
      latitude: -23.55,
      longitude: -46.63,
      accuracyMeters: 4.5,
      capturedAt,
      address: 'Rua Teste',
    };
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'msg-location', conversationId: 'conv-1', senderId: 'user-1',
      clientMessageId: 'location-1', content: null, type: 'LOCATION', metadata,
      createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({
      senderId: 'user-1', conversationId: 'conv-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata,
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectMessage).toHaveBeenCalledWith(
      expect.objectContaining({ clientMessageId: 'location-1', metadata }),
      true,
    );
  });

  it('validates canonical location metadata in an order thread', async () => {
    const capturedAt = new Date().toISOString();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1', orderStatus: 'CONFIRMED' }),
    );
    mockRepo.createChatMessage.mockResolvedValue(right({
      id: 'msg-location', senderId: 'buyer-1', type: 'LOCATION',
      clientMessageId: 'location-1', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 0,
        capturedAt,
      }, createdAt: new Date(),
    }));

    const result = await sut.execute({
      senderId: 'buyer-1', conversationId: 'order-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 0,
        capturedAt,
      },
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createChatMessage).toHaveBeenCalledWith(
      expect.objectContaining({ clientMessageId: 'location-1' }),
      true,
    );
  });

  it('rejects a stale location for a new direct operation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));
    const capturedAt = new Date(Date.now() - 6 * 60 * 1000).toISOString();

    const result = await sut.execute({
      senderId: 'user-1', conversationId: 'conv-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt,
      },
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.findDirectMessageByClientId).toHaveBeenCalledWith(
      'conv-1', 'user-1', 'location-1',
    );
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });

  it('returns an existing direct message for a delayed retry by its sender', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));
    const capturedAt = new Date(Date.now() - 6 * 60 * 1000).toISOString();
    mockRepo.findDirectMessageByClientId.mockResolvedValue(right({
      id: 'msg-location', conversationId: 'conv-1', senderId: 'user-1',
      clientMessageId: 'location-1', content: null, type: 'LOCATION',
      attachmentUrl: null, metadata: { latitude: 0, longitude: 0, accuracyMeters: 1,
        capturedAt },
      replyToId: null, viewOnce: false, createdAt: new Date(),
    }));

    const result = await sut.execute({
      senderId: 'user-1', conversationId: 'conv-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt,
      },
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });

  it('returns an existing order message for a delayed retry by its sender', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1', orderStatus: 'CONFIRMED' }),
    );
    const capturedAt = new Date(Date.now() - 6 * 60 * 1000).toISOString();
    mockRepo.findChatMessageByClientId.mockResolvedValue(right({
      id: 'msg-location', orderId: 'order-1', senderId: 'buyer-1',
      clientMessageId: 'location-1', content: null, type: 'LOCATION',
      attachmentUrl: null, metadata: { latitude: 0, longitude: 0, accuracyMeters: 1,
        capturedAt },
      replyToId: null, viewOnce: false, createdAt: new Date(),
    }));

    const result = await sut.execute({
      senderId: 'buyer-1', conversationId: 'order-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt,
      },
    });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createChatMessage).not.toHaveBeenCalled();
  });

  it('rejects a delayed retry when the existing message is not a location', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));
    const capturedAt = new Date(Date.now() - 6 * 60 * 1000).toISOString();
    mockRepo.findDirectMessageByClientId.mockResolvedValue(right({
      id: 'msg-text', conversationId: 'conv-1', senderId: 'user-1',
      clientMessageId: 'location-1', content: 'text', type: 'TEXT',
      attachmentUrl: null, metadata: null, replyToId: null, viewOnce: false,
      createdAt: new Date(),
    }));

    const result = await sut.execute({
      senderId: 'user-1', conversationId: 'conv-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt,
      },
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });

  it('rejects a delayed retry when location metadata differs', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right({
      id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE',
    }));
    const capturedAt = new Date(Date.now() - 6 * 60 * 1000).toISOString();
    mockRepo.findDirectMessageByClientId.mockResolvedValue(right({
      id: 'msg-location', conversationId: 'conv-1', senderId: 'user-1',
      clientMessageId: 'location-1', content: null, type: 'LOCATION',
      attachmentUrl: null, metadata: { latitude: 1, longitude: 0, accuracyMeters: 1,
        capturedAt },
      replyToId: null, viewOnce: false, createdAt: new Date(),
    }));

    const result = await sut.execute({
      senderId: 'user-1', conversationId: 'conv-1', clientMessageId: 'location-1',
      type: 'LOCATION', metadata: {
        latitude: 0, longitude: 0, accuracyMeters: 1, capturedAt,
      },
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
  });
});
