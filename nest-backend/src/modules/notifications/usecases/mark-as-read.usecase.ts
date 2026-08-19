import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { NotificationRepository } from '../domain/repositories/notification.repository';

@Injectable()
export class MarkAsReadUseCase {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  async execute(notificationId: string, userId: string): Promise<Either<AppError, void>> {
    const findResult = await this.notificationRepository.findById(notificationId);
    if (isLeft(findResult)) return left(findResult.value);

    const notification = findResult.value;
    if (!notification) {
      return left(new NotFoundError('Notification'));
    }

    if (notification.userId !== userId) {
      return left(new ForbiddenError('Not authorized'));
    }

    const markResult = await this.notificationRepository.markAsRead(notificationId);
    if (isLeft(markResult)) return left(markResult.value);

    return right(undefined);
  }
}
