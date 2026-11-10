import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';

@Injectable()
export class RegisterFcmTokenUseCase {
  constructor(private readonly notificationRepository: NotificationDatabaseRepository) {}

  async execute(userId: string, fcmToken: string, installationId: string): Promise<Either<AppError, void>> {
    const result = await this.notificationRepository.updatePushSettings(userId, { fcmToken, installationId });
    if (result.isLeft()) return left(result.value);
    return right(undefined);
  }
}
