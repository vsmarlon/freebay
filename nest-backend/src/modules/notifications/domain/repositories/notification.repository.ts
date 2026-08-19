import { RepositoryResponse } from '@/shared/core/either';
import { Notification } from '@prisma/client';

export abstract class NotificationRepository {
  abstract findByUserId(userId: string, limit?: number): RepositoryResponse<Notification[]>;
  abstract findById(id: string): RepositoryResponse<Notification | null>;
  abstract markAsRead(id: string): RepositoryResponse<void>;
  abstract markAllAsRead(userId: string): RepositoryResponse<void>;
  abstract updateUserFcmToken(userId: string, fcmToken: string): RepositoryResponse<void>;
}
