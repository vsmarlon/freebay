import { Injectable } from '@nestjs/common';
import { Either, isLeft, left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { NotificationRepository } from '../domain/repositories/notification.repository';
import { GetNotificationsOutput } from '../dtos/notification.dto';

@Injectable()
export class GetNotificationsUseCase {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  async execute(userId: string, limit = 20): Promise<Either<AppError, GetNotificationsOutput>> {
    const result = await this.notificationRepository.findByUserId(userId, limit);
    if (isLeft(result)) return left(result.value);
    return result;
  }
}
