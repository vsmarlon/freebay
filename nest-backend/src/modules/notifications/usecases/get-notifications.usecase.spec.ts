import { Test, TestingModule } from '@nestjs/testing';
import { GetNotificationsUseCase } from './get-notifications.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

jest.mock('@/shared/infra/prisma/prisma.service');

const mockPrisma = {
  notification: {
    findMany: jest.fn(),
  },
};

const mockNotifications = [
  {
    id: 'notif-1',
    userId: 'user-123',
    title: 'New order',
    message: 'You have a new order',
    read: false,
    createdAt: new Date(),
  },
  {
    id: 'notif-2',
    userId: 'user-123',
    title: 'Payment received',
    message: 'Payment was confirmed',
    read: true,
    createdAt: new Date(),
  },
];

describe('GetNotificationsUseCase', () => {
  let sut: GetNotificationsUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetNotificationsUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<GetNotificationsUseCase>(GetNotificationsUseCase);
    jest.clearAllMocks();
  });

  it('should return notifications for user', async () => {
    mockPrisma.notification.findMany.mockResolvedValue(mockNotifications);

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(2);
    }
  });

  it('should respect limit parameter', async () => {
    mockPrisma.notification.findMany.mockResolvedValue([mockNotifications[0]]);

    const result = await sut.execute('user-123', 1);

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ take: 1 }),
    );
  });
});
