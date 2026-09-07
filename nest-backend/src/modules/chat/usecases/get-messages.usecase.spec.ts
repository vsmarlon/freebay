import { Test, TestingModule } from '@nestjs/testing';
import { GetMessagesUseCase } from './get-messages.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaConversationPreferenceRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

const mockRepo = {
  findMessagesByConversation: jest.fn(),
  markMessagesRead: jest.fn(),
  findChatMessagesByOrder: jest.fn(),
  markChatMessagesRead: jest.fn(),
};

const mockPreferenceRepo = {
  findByAnyId: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

const page = <T>(items: T[]) => ({ items, hasMore: false, nextCursor: null });

describe('GetMessagesUseCase', () => {
  let sut: GetMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetMessagesUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: PrismaConversationPreferenceRepository, useValue: mockPreferenceRepo },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(GetMessagesUseCase);
    jest.clearAllMocks();
    mockRepo.markMessagesRead.mockResolvedValue(right(undefined));
    mockRepo.markChatMessagesRead.mockResolvedValue(right(undefined));
    mockPreferenceRepo.findByAnyId.mockResolvedValue(right(null));
  });

  it('should return error if thread cannot be resolved', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not a participant', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      left(new ForbiddenError('Você não é participante desta conversa')),
    );

    const result = await sut.execute('conv-1', 'stranger');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should return direct messages and mark unread as read', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.findMessagesByConversation.mockResolvedValue(right(page([
      {
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-2',
        content: 'Hello',
        type: 'TEXT',
        attachmentUrl: null,
        metadata: null,
        replyToId: null,
        replyTo: null,
        deletedAt: null,
        readAt: null,
        deliveredAt: null,
        createdAt: now,
        sender: { id: 'user-2', displayName: 'Other', avatarUrl: null },
      },
    ])));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.threadType).toBe('DIRECT');
      expect(result.value.otherUserId).toBe('user-2');
      expect(result.value.messages).toHaveLength(1);
      expect(result.value.messages[0].content).toBe('Hello');
      expect(result.value.hasMore).toBe(false);
      expect(result.value.nextCursor).toBeNull();
    }
    expect(mockRepo.markMessagesRead).toHaveBeenCalledWith('conv-1', 'user-1');
  });

  it('should read order threads from ChatMessage', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1', orderStatus: 'CONFIRMED' }),
    );
    mockRepo.findChatMessagesByOrder.mockResolvedValue(right(page([
      {
        id: 'msg-1',
        orderId: 'order-1',
        senderId: 'seller-1',
        content: 'A caminho',
        type: 'TEXT',
        attachmentUrl: null,
        metadata: null,
        replyToId: null,
        replyTo: null,
        deletedAt: null,
        readAt: null,
        deliveredAt: null,
        createdAt: now,
        sender: { id: 'seller-1', displayName: 'Seller', avatarUrl: null },
      },
    ])));

    const result = await sut.execute('order-1', 'buyer-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.threadType).toBe('ORDER');
      expect(result.value.messages[0].conversationId).toBe('order-1');
    }
    expect(mockRepo.markChatMessagesRead).toHaveBeenCalledWith('order-1', 'buyer-1');
    expect(mockRepo.findMessagesByConversation).not.toHaveBeenCalled();
  });

  it('should hydrate replyTo and hide content of a deleted original', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.findMessagesByConversation.mockResolvedValue(right(page([
      {
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Respondendo',
        type: 'TEXT',
        attachmentUrl: null,
        metadata: null,
        replyToId: 'msg-1',
        replyTo: {
          id: 'msg-1',
          senderId: 'user-2',
          content: 'Original',
          type: 'TEXT',
          attachmentUrl: null,
          deletedAt: now,
        },
        deletedAt: null,
        readAt: null,
        deliveredAt: null,
        createdAt: now,
        sender: { id: 'user-1', displayName: 'Me', avatarUrl: null },
      },
    ])));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.messages[0].replyToId).toBe('msg-1');
      expect(result.value.messages[0].replyTo?.content).toBeNull();
      expect(result.value.messages[0].replyTo?.deletedAt).toEqual(now);
    }
  });

  it('should return the conversation preference', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.findMessagesByConversation.mockResolvedValue(right(page([])));
    mockPreferenceRepo.findByAnyId.mockResolvedValue(right({
      isArchived: false,
      theme: 'COBALT',
      backgroundUrl: '/uploads/background/abc.jpg',
    }));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.preference).toEqual({
        isArchived: false,
        theme: 'COBALT',
        backgroundUrl: '/uploads/background/abc.jpg',
      });
    }
  });
});
