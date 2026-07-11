import { DeleteMessageUseCase } from './delete-message.usecase';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { right } from '@/shared/core/either';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';

const mockRepo = {
  findDirectMessageById: jest.fn(),
  softDeleteDirectMessage: jest.fn(),
};

describe('DeleteMessageUseCase', () => {
  let sut: DeleteMessageUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    sut = new DeleteMessageUseCase(mockRepo as unknown as ConversationRepository);
  });

  it('returns void on success', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right({ id: 'msg1', senderId: 'user1', deletedAt: null }));
    mockRepo.softDeleteDirectMessage.mockResolvedValue(right(undefined));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isRight()).toBe(true);
  });

  it('returns ForbiddenError when user is not the sender', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right({ id: 'msg1', senderId: 'user2', deletedAt: null }));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('returns NotFoundError when message not found', async () => {
    mockRepo.findDirectMessageById.mockResolvedValue(right(null));

    const result = await sut.execute({ messageId: 'msg1', userId: 'user1', conversationId: 'conv1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });
});
