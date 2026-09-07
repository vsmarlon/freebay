import { Test, TestingModule } from '@nestjs/testing';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ToggleReactionUseCase } from './toggle-reaction.usecase';
import { left, right } from '@/shared/core/either';
import { BadRequestError, ForbiddenError } from '@/shared/core/errors';

const mockRepo = {
  findReactionByUserAndMessage: jest.fn(),
  upsertReaction: jest.fn(),
  deleteReaction: jest.fn(),
  getReactionsForMessage: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

describe('ToggleReactionUseCase', () => {
  let sut: ToggleReactionUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'c1', otherUserId: 'u2' }),
    );

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ToggleReactionUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(ToggleReactionUseCase);
  });

  it('adds reaction when user has none', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.upsertReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([{ emoji: '❤️', userId: 'u1' }]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', conversationId: 'c1' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.upsertReaction).toHaveBeenCalledWith(
      expect.objectContaining({ model: 'DIRECT' }),
    );
  });

  it('removes reaction when user taps same emoji again', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right({ id: 'r1', emoji: '❤️' }));
    mockRepo.deleteReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', conversationId: 'c1' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.deleteReaction).toHaveBeenCalledWith('r1');
  });

  it('resolves the ORDER model for order threads', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'u2' }),
    );
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.upsertReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([{ emoji: '❤️', userId: 'u1' }]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', conversationId: 'order-1' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.upsertReaction).toHaveBeenCalledWith(
      expect.objectContaining({ model: 'ORDER' }),
    );
    expect(mockRepo.getReactionsForMessage).toHaveBeenCalledWith('m1', 'ORDER');
  });

  it('rejects a non-participant', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      left(new ForbiddenError('Você não é participante desta conversa')),
    );

    const result = await sut.execute({ userId: 'stranger', messageId: 'm1', emoji: '❤️', conversationId: 'c1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
    expect(mockRepo.upsertReaction).not.toHaveBeenCalled();
  });

  it('rejects invalid emoji', async () => {
    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '🥳', conversationId: 'c1' });
    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
  });
});
