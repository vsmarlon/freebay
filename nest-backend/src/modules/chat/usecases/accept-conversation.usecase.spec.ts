import { Test, TestingModule } from '@nestjs/testing';
import { AcceptConversationUseCase } from './accept-conversation.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';

const mockPrisma = {
  directConversation: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
};

describe('AcceptConversationUseCase', () => {
  let sut: AcceptConversationUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AcceptConversationUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<AcceptConversationUseCase>(AcceptConversationUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue(null);
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not a participant', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'a', user2Id: 'b', status: 'PENDING' });
    const result = await sut.execute('conv-1', 'stranger');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return error if conversation is not PENDING', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'ACTIVE' });
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should accept conversation successfully', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2', status: 'PENDING' });
    mockPrisma.directConversation.update.mockResolvedValue({ id: 'conv-1', status: 'ACTIVE' });

    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.accepted).toBe(true);
    expect(mockPrisma.directConversation.update).toHaveBeenCalledWith({
      where: { id: 'conv-1' },
      data: { status: 'ACTIVE' },
    });
  });
});
