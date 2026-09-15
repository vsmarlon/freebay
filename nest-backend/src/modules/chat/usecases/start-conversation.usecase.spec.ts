import { Test, TestingModule } from '@nestjs/testing';
import { StartConversationUseCase } from './start-conversation.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findUserById: jest.fn().mockResolvedValue(right({ id: 'user-2', displayName: 'Jane', avatarUrl: null })),
  findDirectConversationBetweenUsers: jest.fn(),
  findProductConversationBetweenUsers: jest.fn(),
  findProductSummary: jest.fn(),
  createDirectConversation: jest.fn(),
  createDirectMessage: jest.fn(),
  findFollow: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn().mockResolvedValue(right(false)),
};

describe('StartConversationUseCase', () => {
  let sut: StartConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StartConversationUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: PrismaBlockRepository, useValue: mockBlockRepository },
      ],
    }).compile();

    sut = module.get(StartConversationUseCase);
    jest.clearAllMocks();
  });

  it('returns error if starting conversation with self', async () => {
    const result = await sut.execute('user-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns existing conversation if one exists', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right({
      conversationId: 'conv-1',
      status: 'ACTIVE',
      threadType: 'DIRECT',
      product: null,
    }));
    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.conversationId).toBe('conv-1');
      expect(result.value.status).toBe('ACTIVE');
      expect(result.value.otherUser).toEqual({ id: 'user-2', displayName: 'Jane', avatarUrl: null });
      expect(Object.keys(result.value).sort()).toEqual(['conversationId', 'otherUser', 'product', 'status', 'threadType']);
    }
  });

  it('creates ACTIVE conversation if following', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right({ id: 'follow-1' }));
    mockRepo.createDirectConversation.mockResolvedValue(right({
      conversationId: 'conv-2',
      status: 'ACTIVE',
      threadType: 'DIRECT',
      product: null,
    }));

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('ACTIVE');
      expect(result.value.otherUser).toEqual({ id: 'user-2', displayName: 'Jane', avatarUrl: null });
    }
  });

  it('creates PENDING conversation if not following', async () => {
    mockRepo.findDirectConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right(null));
    mockRepo.createDirectConversation.mockResolvedValue(right({
      conversationId: 'conv-3',
      status: 'PENDING',
      threadType: 'DIRECT',
      product: null,
    }));

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('PENDING');
      expect(result.value.otherUser).toEqual({ id: 'user-2', displayName: 'Jane', avatarUrl: null });
    }
  });

  it('rejects a product conversation when the target is not the seller', async () => {
    mockRepo.findProductSummary.mockResolvedValue(right({ sellerId: 'seller-1' }));

    const result = await sut.execute('buyer-1', 'buyer-2', 'product-1');

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectConversation).not.toHaveBeenCalled();
  });

  it('creates a product-scoped conversation without creating a message', async () => {
    mockRepo.findProductSummary.mockResolvedValue(right({ sellerId: 'seller-1' }));
    mockRepo.findProductConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right(null));
    mockRepo.createDirectConversation.mockResolvedValue(right({
      conversationId: 'product-conv-1',
      status: 'PENDING',
      threadType: 'DIRECT',
      product: { id: 'product-1', title: 'Item', imageUrl: null, status: 'ACTIVE' },
    }));

    const result = await sut.execute('buyer-1', 'seller-1', 'product-1');

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectConversation).toHaveBeenCalledWith(expect.objectContaining({
      scopeKey: 'PRODUCT:product-1',
      product: { connect: { id: 'product-1' } },
    }));
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
    expect(result.isRight() && result.value.product).toEqual({
      id: 'product-1', title: 'Item', imageUrl: null, status: 'ACTIVE',
    });
  });

  it('uses distinct exact scopes for different products', async () => {
    mockRepo.findProductSummary.mockResolvedValue(right({ sellerId: 'seller-1' }));
    mockRepo.findProductConversationBetweenUsers.mockResolvedValue(right(null));
    mockRepo.findFollow.mockResolvedValue(right(null));
    mockRepo.createDirectConversation
      .mockResolvedValueOnce(right({ conversationId: 'product-conv-1', status: 'PENDING', threadType: 'DIRECT', product: null }))
      .mockResolvedValueOnce(right({ conversationId: 'product-conv-2', status: 'PENDING', threadType: 'DIRECT', product: null }));

    await sut.execute('buyer-1', 'seller-1', 'product-1');
    await sut.execute('buyer-1', 'seller-1', 'product-2');

    expect(mockRepo.createDirectConversation.mock.calls.map(([data]) => data.scopeKey)).toEqual([
      'PRODUCT:product-1', 'PRODUCT:product-2',
    ]);
  });

  it('reuses the canonical conversation for the same product', async () => {
    mockRepo.findProductSummary.mockResolvedValue(right({ sellerId: 'seller-1' }));
    mockRepo.findProductConversationBetweenUsers.mockResolvedValue(right({
      conversationId: 'canonical', status: 'ACTIVE', threadType: 'DIRECT', product: null,
    }));

    const result = await sut.execute('buyer-1', 'seller-1', 'product-1');

    expect(result.isRight()).toBe(true);
    expect(mockRepo.createDirectConversation).not.toHaveBeenCalled();
  });

});
