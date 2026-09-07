import { Test, TestingModule } from '@nestjs/testing';
import { ForwardMessagesUseCase } from './forward-messages.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BadRequestError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockPrisma = {
  directMessage: {
    findMany: jest.fn(),
  },
  chatMessage: {
    findMany: jest.fn(),
  },
};

const mockRepo = {
  createDirectMessage: jest.fn(),
  updateDirectConversation: jest.fn(),
  createChatMessage: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

describe('ForwardMessagesUseCase', () => {
  let sut: ForwardMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ForwardMessagesUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: PrismaBlockRepository, useValue: mockBlockRepository },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(ForwardMessagesUseCase);
    jest.clearAllMocks();
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
  });

  it('should return error when no message IDs provided', async () => {
    const result = await sut.execute({
      userId: 'user-1',
      messageIds: [],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error when no target conversation IDs provided', async () => {
    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: [],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error when source messages not found', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if recipient has blocked user', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([
      { id: 'msg-1', content: 'Hey', type: 'TEXT', attachmentUrl: null, metadata: null, sender: { displayName: 'John' } },
    ]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'conv-1', otherUserId: 'user-blocked' }));
    mockBlockRepository.isBlocked.mockResolvedValueOnce(right(true));

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should successfully forward messages to target direct conversations', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([
      { id: 'msg-1', content: 'Hello World', type: 'TEXT', attachmentUrl: null, metadata: null, sender: { displayName: 'John' } },
    ]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'conv-target', otherUserId: 'user-2' }));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'new-msg-1',
      conversationId: 'conv-target',
      senderId: 'user-1',
      content: 'Hello World',
      type: 'TEXT',
      attachmentUrl: null,
      createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-target'],
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.forwardedCount).toBe(1);
      expect(result.value.messages[0].content).toBe('Hello World');
      expect(result.value.messages[0].metadata).toEqual(expect.objectContaining({
        isForwarded: true,
        forwardedFrom: 'John',
      }));
    }
  });
});
