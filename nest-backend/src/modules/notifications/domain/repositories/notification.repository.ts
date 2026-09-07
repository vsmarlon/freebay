import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { Notification } from '@prisma/client';

export abstract class NotificationRepository {
  abstract findByUserId(
    userId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<Notification>>;
  abstract findById(id: string): RepositoryResponse<Notification | null>;
  abstract countUnread(userId: string): RepositoryResponse<number>;
  abstract markAsRead(id: string): RepositoryResponse<void>;
  abstract markAllAsRead(userId: string): RepositoryResponse<void>;
  abstract updateUserFcmToken(userId: string, fcmToken: string): RepositoryResponse<void>;
}
