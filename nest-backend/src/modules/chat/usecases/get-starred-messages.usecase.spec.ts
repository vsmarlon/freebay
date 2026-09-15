import { Test, TestingModule } from '@nestjs/testing';
import { GetStarredMessagesUseCase } from './get-starred-messages.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { NotFoundError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

const mockRepo = {
  findStarredMessages: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

const directStar = {
  id: 'msg-1',
  senderId: 'user-2',
  content: 'Lembrete',
  type: 'TEXT',
  attachmentUrl: null,
  metadata: null,
  replyToId: null,
  replyTo: null,
  deletedAt: null,
  readAt: null,
  deliveredAt: null,
  createdAt: new Date('2026-06-24'),
  viewOnce: false,
};

describe('GetStarredMessagesUseCase', () => {
  let sut: GetStarredMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetStarredMessagesUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(GetStarredMessagesUseCase);
    jest.clearAllMocks();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
  });

  it('deve retornar erro quando a conversa nao pode ser resolvida', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.findStarredMessages).not.toHaveBeenCalled();
  });

  it('deve retornar lista vazia quando nao ha favoritas', async () => {
    mockRepo.findStarredMessages.mockResolvedValue(right([]));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual([]);
  });

  it('deve mapear favoritas diretas com o id da conversa', async () => {
    mockRepo.findStarredMessages.mockResolvedValue(right([directStar]));

    const result = await sut.execute('conv-1', 'user-1');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].id).toBe('msg-1');
      expect(result.value[0].conversationId).toBe('conv-1');
      expect(result.value[0].content).toBe('Lembrete');
    }
    expect(mockRepo.findStarredMessages).toHaveBeenCalledWith('user-1', 'conv-1', 'DIRECT');
  });

  it('deve buscar pelo pedido em conversa de pedido', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1' }),
    );
    mockRepo.findStarredMessages.mockResolvedValue(right([]));

    const result = await sut.execute('order-1', 'buyer-1');

    expect(result.isRight()).toBe(true);
    expect(mockRepo.findStarredMessages).toHaveBeenCalledWith('buyer-1', 'order-1', 'ORDER');
  });
});
