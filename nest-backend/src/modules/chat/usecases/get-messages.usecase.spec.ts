import { Test, TestingModule } from '@nestjs/testing';
import { GetMessagesUseCase } from './get-messages.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaConversationPreferenceRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';
import { directMessage, orderMessage } from './test-fixtures';

const mockRepo = {
  findMessagesByConversation: jest.fn(),
  markMessagesRead: jest.fn(),
  findChatMessagesByOrder: jest.fn(),
  markChatMessagesRead: jest.fn(),
  findUserById: jest.fn(),
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
    mockRepo.findUserById.mockImplementation((id: string) =>
      Promise.resolve(right({ id, displayName: 'Other', avatarUrl: null })),
    );
    mockPreferenceRepo.findByAnyId.mockResolvedValue(right(null));
  });

  it('returns error if thread cannot be resolved', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if user is not a participant', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      left(new ForbiddenError('Você não é participante desta conversa')),
    );

    const result = await sut.execute('conv-1', 'stranger');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('returns direct messages and marks unread as read', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.findMessagesByConversation.mockResolvedValue(right(page([
      directMessage({
        senderId: 'user-2', createdAt: now,
        sender: { id: 'user-2', displayName: 'Other', avatarUrl: null },
      }),
    ])));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.threadType).toBe('DIRECT');
      expect(result.value.otherUserId).toBe('user-2');
      expect(result.value.otherUser).toEqual({ id: 'user-2', displayName: 'Other', avatarUrl: null });
      expect(result.value.messages).toHaveLength(1);
      expect(result.value.messages[0].content).toBe('Hello');
      expect(result.value.hasMore).toBe(false);
      expect(result.value.nextCursor).toBeNull();
    }
    expect(mockRepo.markMessagesRead).toHaveBeenCalledWith('conv-1', 'user-1');
  });

  it('reads order threads from ChatMessage', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1', orderStatus: 'CONFIRMED' }),
    );
    mockRepo.findChatMessagesByOrder.mockResolvedValue(right(page([
      orderMessage({
        senderId: 'seller-1', content: 'A caminho', createdAt: now,
        sender: { id: 'seller-1', displayName: 'Seller', avatarUrl: null },
      }),
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

  it('hydrates replyTo and hides content of a deleted original', async () => {
    const now = new Date();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.findMessagesByConversation.mockResolvedValue(right(page([
      directMessage({
        id: 'msg-2', senderId: 'user-1', content: 'Respondendo', replyToId: 'msg-1',
        replyTo: {
          id: 'msg-1',
          senderId: 'user-2',
          content: 'Original',
          type: 'TEXT',
          attachmentUrl: null,
          deletedAt: now,
        },
        createdAt: now,
        sender: { id: 'user-1', displayName: 'Me', avatarUrl: null },
      }),
    ])));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.messages[0].replyToId).toBe('msg-1');
      expect(result.value.messages[0].replyTo?.content).toBeNull();
      expect(result.value.messages[0].replyTo?.deletedAt).toEqual(now);
    }
  });

  it('returns the conversation preference', async () => {
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
