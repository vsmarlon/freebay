import { Test, TestingModule } from '@nestjs/testing';
import { MarkAsReadUseCase } from './mark-as-read.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, AppError } from '@/shared/core/errors';

jest.mock('@/shared/infra/prisma/prisma.service');

const mockPrisma = {
  notification: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
};

describe('MarkAsReadUseCase', () => {
  let sut: MarkAsReadUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MarkAsReadUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<MarkAsReadUseCase>(MarkAsReadUseCase);
    jest.clearAllMocks();
  });

  it('should mark notification as read', async () => {
    mockPrisma.notification.findUnique.mockResolvedValue({
      id: 'notif-1',
      userId: 'user-123',
    });
    mockPrisma.notification.update.mockResolvedValue({});

    const result = await sut.execute('notif-1', 'user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
  });

  it('should return NotFoundError when notification not found', async () => {
    mockPrisma.notification.findUnique.mockResolvedValue(null);

    const result = await sut.execute('nonexistent', 'user-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return error when user does not own notification', async () => {
    mockPrisma.notification.findUnique.mockResolvedValue({
      id: 'notif-1',
      userId: 'other-user',
    });

    const result = await sut.execute('notif-1', 'user-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(AppError);
    }
  });
});
