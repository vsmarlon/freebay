import { Test, TestingModule } from '@nestjs/testing';
import { SendMessageUseCase } from './send-message.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';

const mockPrisma = {
  directConversation: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  directMessage: {
    create: jest.fn(),
  },
};

const mockBlockRepository = {
  isBlocked: jest.fn().mockResolvedValue(false),
};

describe('SendMessageUseCase', () => {
  let sut: SendMessageUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SendMessageUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: BlockRepository, useValue: mockBlockRepository },
      ],
    }).compile();

    sut = module.get<SendMessageUseCase>(SendMessageUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue(null);
    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if conversation is pending and user not participant', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' });
    const result = await sut.execute({ senderId: 'stranger', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should send message successfully in active conversation', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' });
    mockPrisma.directMessage.create.mockResolvedValue({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hello', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    });
    mockPrisma.directConversation.update.mockResolvedValue({});

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hello' });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.content).toBe('Hello');
      expect(result.value.conversationId).toBe('conv-1');
    }
  });

  it('should allow participant to send in pending conversation', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'PENDING' });
    mockPrisma.directMessage.create.mockResolvedValue({
      id: 'msg-1', conversationId: 'conv-1', senderId: 'user-1', content: 'Hi', type: 'TEXT', createdAt: new Date(),
      sender: { id: 'user-1', displayName: 'John', avatarUrl: null },
    });
    mockPrisma.directConversation.update.mockResolvedValue({});

    const result = await sut.execute({ senderId: 'user-1', conversationId: 'conv-1', content: 'Hi' });
    expect(result.isRight()).toBe(true);
  });
});
