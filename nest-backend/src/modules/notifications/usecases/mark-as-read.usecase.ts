import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';

@Injectable()
export class MarkAsReadUseCase {
  constructor(private readonly notificationRepository: NotificationDatabaseRepository) {}

  async execute(notificationId: string, userId: string): Promise<Either<AppError, void>> {
    const findResult = await this.notificationRepository.findById(notificationId);
    if (findResult.isLeft()) return left(findResult.value);

    const notification = findResult.value;
    if (!notification) {
      return left(new NotFoundError('Notification'));
    }

    if (notification.userId !== userId) {
      return left(new ForbiddenError('Not authorized'));
    }

    const markResult = await this.notificationRepository.markAsRead(notificationId);
    if (markResult.isLeft()) return left(markResult.value);

    return right(undefined);
  }
}
