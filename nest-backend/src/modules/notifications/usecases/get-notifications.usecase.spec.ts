import { Test, TestingModule } from '@nestjs/testing';
import { GetNotificationsUseCase } from './get-notifications.usecase';
import { NotificationRepository } from '../domain/repositories/notification.repository';
import { right } from '@/shared/core/either';

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
  let mockNotificationRepository: { findByUserId: jest.Mock };

  beforeEach(async () => {
    mockNotificationRepository = { findByUserId: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetNotificationsUseCase,
        { provide: NotificationRepository, useValue: mockNotificationRepository },
      ],
    }).compile();

    sut = module.get<GetNotificationsUseCase>(GetNotificationsUseCase);
    jest.clearAllMocks();
  });

  it('should return notifications for user', async () => {
    mockNotificationRepository.findByUserId.mockResolvedValue(
      right({ items: mockNotifications, hasMore: false, nextCursor: null }),
    );

    const result = await sut.execute('user-123', { limit: 20 });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.items).toHaveLength(2);
      expect(result.value.hasMore).toBe(false);
    }
  });

  it('should pass the page query straight through to the repository', async () => {
    mockNotificationRepository.findByUserId.mockResolvedValue(
      right({ items: [mockNotifications[0]], hasMore: true, nextCursor: 'abc' }),
    );

    const page = { limit: 1, cursor: 'n-1' };
    const result = await sut.execute('user-123', page);

    expect(result.isRight()).toBe(true);
    expect(mockNotificationRepository.findByUserId).toHaveBeenCalledWith('user-123', page);
  });
});
