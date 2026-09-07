import { Injectable } from '@nestjs/common';
import { Either, isLeft, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { Notification } from '@prisma/client';
import { NotificationRepository } from '../domain/repositories/notification.repository';

@Injectable()
export class GetNotificationsUseCase {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  async execute(
    userId: string,
    page: PageQuery,
  ): Promise<Either<AppError, CursorPage<Notification>>> {
    const result = await this.notificationRepository.findByUserId(userId, page);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
