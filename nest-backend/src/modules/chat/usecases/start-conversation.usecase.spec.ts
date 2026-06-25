import { Test, TestingModule } from '@nestjs/testing';
import { StartConversationUseCase } from './start-conversation.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { BadRequestError } from '@/shared/core/errors';

const mockPrisma = {
  user: {
    findUnique: jest.fn().mockResolvedValue({ id: 'user-2', displayName: 'Jane' }),
  },
  directConversation: {
    findFirst: jest.fn(),
    create: jest.fn(),
  },
  follow: {
    findFirst: jest.fn(),
  },
};

const mockBlockRepository = {
  isBlocked: jest.fn().mockResolvedValue(false),
};

describe('StartConversationUseCase', () => {
  let sut: StartConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StartConversationUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: BlockRepository, useValue: mockBlockRepository },
      ],
    }).compile();

    sut = module.get<StartConversationUseCase>(StartConversationUseCase);
    jest.clearAllMocks();
  });

  it('should return error if starting conversation with self', async () => {
    const result = await sut.execute('user-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return existing conversation if one exists', async () => {
    mockPrisma.directConversation.findFirst.mockResolvedValue({ id: 'conv-1', status: 'ACTIVE' });
    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.conversationId).toBe('conv-1');
      expect(result.value.status).toBe('ACTIVE');
    }
  });

  it('should create ACTIVE conversation if following', async () => {
    mockPrisma.directConversation.findFirst.mockResolvedValue(null);
    mockPrisma.follow.findFirst.mockResolvedValue({ id: 'follow-1' });
    mockPrisma.directConversation.create.mockResolvedValue({ id: 'conv-2', status: 'ACTIVE' });

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('ACTIVE');
    }
  });

  it('should create PENDING conversation if not following', async () => {
    mockPrisma.directConversation.findFirst.mockResolvedValue(null);
    mockPrisma.follow.findFirst.mockResolvedValue(null);
    mockPrisma.directConversation.create.mockResolvedValue({ id: 'conv-3', status: 'PENDING' });

    const result = await sut.execute('user-1', 'user-2');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.status).toBe('PENDING');
    }
  });
});
