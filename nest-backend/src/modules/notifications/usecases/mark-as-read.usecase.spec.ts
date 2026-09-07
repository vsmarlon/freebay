import { Test, TestingModule } from '@nestjs/testing';
import { MarkAsReadUseCase } from './mark-as-read.usecase';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

describe('MarkAsReadUseCase', () => {
  let sut: MarkAsReadUseCase;
  let mockNotificationRepository: {
    findById: jest.Mock;
    markAsRead: jest.Mock;
  };

  beforeEach(async () => {
    mockNotificationRepository = {
      findById: jest.fn(),
      markAsRead: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MarkAsReadUseCase,
        { provide: NotificationDatabaseRepository, useValue: mockNotificationRepository },
      ],
    }).compile();

    sut = module.get(MarkAsReadUseCase);
    jest.clearAllMocks();
  });

  it('should mark notification as read', async () => {
    mockNotificationRepository.findById.mockResolvedValue(
      right({ id: 'notif-1', userId: 'user-123' }),
    );

    const result = await sut.execute('notif-1', 'user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
    expect(mockNotificationRepository.markAsRead).toHaveBeenCalledWith('notif-1');
  });

  it('should return NotFoundError when notification not found', async () => {
    mockNotificationRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute('nonexistent', 'user-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return ForbiddenError when user does not own notification', async () => {
    mockNotificationRepository.findById.mockResolvedValue(
      right({ id: 'notif-1', userId: 'other-user' }),
    );

    const result = await sut.execute('notif-1', 'user-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(ForbiddenError);
    }
    expect(mockNotificationRepository.markAsRead).not.toHaveBeenCalled();
  });
});
