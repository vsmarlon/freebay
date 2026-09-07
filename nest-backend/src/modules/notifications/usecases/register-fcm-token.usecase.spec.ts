import { Test, TestingModule } from '@nestjs/testing';
import { RegisterFcmTokenUseCase } from './register-fcm-token.usecase';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';
import { right } from '@/shared/core/either';

describe('RegisterFcmTokenUseCase', () => {
  let sut: RegisterFcmTokenUseCase;
  let mockNotificationRepository: { updateUserFcmToken: jest.Mock };

  beforeEach(async () => {
    mockNotificationRepository = {
      updateUserFcmToken: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegisterFcmTokenUseCase,
        { provide: NotificationDatabaseRepository, useValue: mockNotificationRepository },
      ],
    }).compile();

    sut = module.get(RegisterFcmTokenUseCase);
    jest.clearAllMocks();
  });

  it('should register FCM token successfully', async () => {
    const result = await sut.execute('user-123', 'fcm-token-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
    expect(mockNotificationRepository.updateUserFcmToken).toHaveBeenCalledWith(
      'user-123',
      'fcm-token-123',
    );
  });
});
