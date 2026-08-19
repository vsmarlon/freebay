import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { NotificationRepository } from '../../domain/repositories/notification.repository';
import { Notification } from '@prisma/client';

@Injectable()
export class NotificationDatabaseRepository extends BasePrismaRepository implements NotificationRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserId(userId: string, limit = 20): RepositoryResponse<Notification[]> {
    return this.safeRun(() => this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    }), 'Failed to fetch notifications');
  }

  async findById(id: string): RepositoryResponse<Notification | null> {
    return this.safeRun(() => this.prisma.notification.findUnique({
      where: { id },
    }), 'Failed to fetch notification');
  }

  async markAsRead(id: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.notification.update({ where: { id }, data: { read: true } });
    }, 'Failed to mark notification as read');
  }

  async markAllAsRead(userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.notification.updateMany({ where: { userId, read: false }, data: { read: true } });
    }, 'Failed to mark all notifications as read');
  }

  async updateUserFcmToken(userId: string, fcmToken: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.user.update({ where: { id: userId }, data: { fcmToken } });
    }, 'Failed to update FCM token');
  }
}
