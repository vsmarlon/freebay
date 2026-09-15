import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { Notification } from '@prisma/client';
import { NotificationDatabaseRepository } from '../data/repositories/notification-database.repository';

@Injectable()
export class GetNotificationsUseCase {
  constructor(private readonly notificationRepository: NotificationDatabaseRepository) {}

  async execute(
    userId: string,
    page: PageQuery,
  ): Promise<Either<AppError, CursorPage<Notification>>> {
    const result = await this.notificationRepository.findByUserId(userId, page);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
