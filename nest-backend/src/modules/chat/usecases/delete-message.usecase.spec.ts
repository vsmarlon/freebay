import { Test, TestingModule } from '@nestjs/testing';
import { DeleteMessageUseCase } from './delete-message.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { right } from '@/shared/core/either';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';

const mockRepo = {
  findReplyToSummary: jest.fn(),
  softDeleteMessage: jest.fn(),
};

describe('DeleteMessageUseCase', () => {
  let sut: DeleteMessageUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteMessageUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: ChatThreadAccessService, useValue: { resolveThread: jest.fn().mockResolvedValue(right({ directConversationId: 'conv1', otherUserId: 'user2' })) } },
      ],
    }).compile();

    sut = module.get(DeleteMessageUseCase);
  });

  it('returns void on success', async () => {
    mockRepo.findReplyToSummary.mockResolvedValue(right({ id: 'msg1', conversationId: 'conv1', senderId: 'user1', deletedAt: null }));
    mockRepo.softDeleteMessage.mockResolvedValue(right(true));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isRight()).toBe(true);
  });

  it('returns ForbiddenError when user is not the sender', async () => {
    mockRepo.findReplyToSummary.mockResolvedValue(right({ id: 'msg1', conversationId: 'conv1', senderId: 'user2', deletedAt: null }));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('returns NotFoundError when message not found', async () => {
    mockRepo.findReplyToSummary.mockResolvedValue(right(null));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });
});
