import { ToggleReactionUseCase } from './toggle-reaction.usecase';
import { right } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';

const mockRepo = {
  findReactionByUserAndMessage: jest.fn(),
  upsertReaction: jest.fn(),
  deleteReaction: jest.fn(),
  getReactionsForMessage: jest.fn(),
};

describe('ToggleReactionUseCase', () => {
  let sut: ToggleReactionUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    sut = new ToggleReactionUseCase(mockRepo as any);
  });

  it('adds reaction when user has none', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.upsertReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([{ emoji: '❤️', userId: 'u1' }]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', messageModel: 'DIRECT' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.upsertReaction).toHaveBeenCalled();
  });

  it('removes reaction when user taps same emoji again', async () => {
    mockRepo.findReactionByUserAndMessage.mockResolvedValue(right({ id: 'r1', emoji: '❤️' }));
    mockRepo.deleteReaction.mockResolvedValue(right(undefined));
    mockRepo.getReactionsForMessage.mockResolvedValue(right([]));

    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '❤️', messageModel: 'DIRECT' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.deleteReaction).toHaveBeenCalledWith('r1');
  });

  it('rejects invalid emoji', async () => {
    const result = await sut.execute({ userId: 'u1', messageId: 'm1', emoji: '🥳', messageModel: 'DIRECT' });
    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
  });
});
