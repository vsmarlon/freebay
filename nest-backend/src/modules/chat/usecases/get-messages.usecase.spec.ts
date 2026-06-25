import { Test, TestingModule } from '@nestjs/testing';
import { GetMessagesUseCase } from './get-messages.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';

const mockPrisma = {
  directConversation: {
    findUnique: jest.fn(),
  },
  directMessage: {
    findMany: jest.fn(),
    updateMany: jest.fn(),
  },
};

describe('GetMessagesUseCase', () => {
  let sut: GetMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetMessagesUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<GetMessagesUseCase>(GetMessagesUseCase);
    jest.clearAllMocks();
  });

  it('should return error if conversation not found', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue(null);
    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user is not a participant', async () => {
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'a', user2Id: 'b' });
    const result = await sut.execute('conv-1', 'stranger');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should return messages and mark unread as read', async () => {
    const now = new Date();
    mockPrisma.directConversation.findUnique.mockResolvedValue({ id: 'conv-1', user1Id: 'user-1', user2Id: 'user-2' });
    mockPrisma.directMessage.findMany.mockResolvedValue([
      { id: 'msg-1', conversationId: 'conv-1', senderId: 'user-2', content: 'Hello', type: 'TEXT', readAt: null, createdAt: now, sender: { id: 'user-2', displayName: 'Other', avatarUrl: null } },
    ]);
    mockPrisma.directMessage.updateMany.mockResolvedValue({ count: 1 });

    const result = await sut.execute('conv-1', 'user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].content).toBe('Hello');
      expect(mockPrisma.directMessage.updateMany).toHaveBeenCalledWith({
        where: { conversationId: 'conv-1', senderId: { not: 'user-1' }, readAt: null },
        data: { readAt: expect.any(Date), deliveredAt: expect.any(Date) },
      });
    }
  });
});
