import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { NotificationRepository } from '../domain/repositories/notification.repository';

@Injectable()
export class MarkAllAsReadUseCase {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  async execute(userId: string): Promise<Either<AppError, void>> {
    const result = await this.notificationRepository.markAllAsRead(userId);
    if (isLeft(result)) return left(result.value);
    return right(undefined);
  }
}
