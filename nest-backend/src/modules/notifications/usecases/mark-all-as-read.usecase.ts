import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';

@Injectable()
export class MarkAllAsReadUseCase {
  constructor(private readonly notificationRepository: NotificationDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, void>> {
    const result = await this.notificationRepository.markAllAsRead(userId);
    if (isLeft(result)) return left(result.value);
    return right(undefined);
  }
}
