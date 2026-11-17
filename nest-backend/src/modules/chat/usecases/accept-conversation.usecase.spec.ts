import { Test, TestingModule } from '@nestjs/testing';
import { AcceptConversationUseCase } from './accept-conversation.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ConflictError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findDirectConversationById: jest.fn(),
  acceptDirectConversation: jest.fn(),
};

const conversation = (overrides: Record<string, unknown> = {}) => ({
  id: 'conv-1',
  user1Id: 'user-1',
  user2Id: 'user-2',
  initiatorId: 'user-1',
  status: 'PENDING',
  ...overrides,
});

describe('AcceptConversationUseCase', () => {
  let sut: AcceptConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AcceptConversationUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get(AcceptConversationUseCase);
    jest.clearAllMocks();
    mockRepo.acceptDirectConversation.mockResolvedValue(right(true));
  });

  it('returns error if conversation not found', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(null));
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if user is not a participant', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(conversation()));
    const result = await sut.execute('conv-1', 'stranger');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns error when the initiator tries to accept their own request', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(conversation()));
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockRepo.acceptDirectConversation).not.toHaveBeenCalled();
  });

  it('returns error if conversation is not PENDING', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(conversation({ status: 'ACTIVE' })));
    const result = await sut.execute('conv-1', 'user-2');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns ConflictError when the guarded acceptance loses the race', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(conversation()));
    mockRepo.acceptDirectConversation.mockResolvedValue(right(false));

    const result = await sut.execute('conv-1', 'user-2');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(ConflictError);
  });

  it('lets the non-initiator accept a PENDING conversation', async () => {
    mockRepo.findDirectConversationById.mockResolvedValue(right(conversation()));

    const result = await sut.execute('conv-1', 'user-2');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.accepted).toBe(true);
    expect(mockRepo.acceptDirectConversation).toHaveBeenCalledWith('conv-1');
  });
});
