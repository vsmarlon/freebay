import { Test, TestingModule } from '@nestjs/testing';
import { GetNotificationsUseCase, MarkAsReadUseCase, RegisterFcmTokenUseCase } from './notification.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, AppError } from '@/shared/core/errors';

jest.mock('@/shared/infra/prisma/prisma.service');

const mockPrisma = {
  notification: {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  user: {
    update: jest.fn(),
  },
};

describe('Notifications UseCases', () => {
  let getNotificationsUseCase: GetNotificationsUseCase;
  let markAsReadUseCase: MarkAsReadUseCase;
  let registerFcmTokenUseCase: RegisterFcmTokenUseCase;

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

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetNotificationsUseCase,
        MarkAsReadUseCase,
        RegisterFcmTokenUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    getNotificationsUseCase = module.get<GetNotificationsUseCase>(GetNotificationsUseCase);
    markAsReadUseCase = module.get<MarkAsReadUseCase>(MarkAsReadUseCase);
    registerFcmTokenUseCase = module.get<RegisterFcmTokenUseCase>(RegisterFcmTokenUseCase);

    jest.clearAllMocks();
  });

  describe('GetNotificationsUseCase', () => {
    it('should return notifications for user', async () => {
      mockPrisma.notification.findMany.mockResolvedValue(mockNotifications);

      const result = await getNotificationsUseCase.execute('user-123');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value).toHaveLength(2);
      }
    });

    it('should respect limit parameter', async () => {
      mockPrisma.notification.findMany.mockResolvedValue([mockNotifications[0]]);

      const result = await getNotificationsUseCase.execute('user-123', 1);

      expect(result.isRight()).toBe(true);
      expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ take: 1 }),
      );
    });
  });

  describe('MarkAsReadUseCase', () => {
    it('should mark notification as read', async () => {
      mockPrisma.notification.findUnique.mockResolvedValue({
        id: 'notif-1',
        userId: 'user-123',
      });
      mockPrisma.notification.update.mockResolvedValue({});

      const result = await markAsReadUseCase.execute('notif-1', 'user-123');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.marked).toBe(true);
      }
    });

    it('should return NotFoundError when notification not found', async () => {
      mockPrisma.notification.findUnique.mockResolvedValue(null);

      const result = await markAsReadUseCase.execute('nonexistent', 'user-123');

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

      const result = await markAsReadUseCase.execute('notif-1', 'user-123');

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(AppError);
      }
    });
  });

  describe('RegisterFcmTokenUseCase', () => {
    it('should register FCM token successfully', async () => {
      mockPrisma.user.update.mockResolvedValue({});

      const result = await registerFcmTokenUseCase.execute('user-123', 'fcm-token-123');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.registered).toBe(true);
      }
      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        data: { fcmToken: 'fcm-token-123' },
      });
    });
  });
});
