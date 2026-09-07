import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { Notification, Prisma } from '@prisma/client';

@Injectable()
export class NotificationDatabaseRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserId(
    userId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<Notification>> {
    return this.safeRun(
      () =>
        paginateById<Notification, Prisma.NotificationFindManyArgs>(
          (args) => this.prisma.notification.findMany(args),
          { where: { userId }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] },
          page,
        ),
      'Failed to fetch notifications',
    );
  }

  async findById(id: string): RepositoryResponse<Notification | null> {
    return this.safeRun(() => this.prisma.notification.findUnique({
      where: { id },
    }), 'Failed to fetch notification');
  }

  async countUnread(userId: string): RepositoryResponse<number> {
    return this.safeRun(
      () => this.prisma.notification.count({ where: { userId, read: false } }),
      'Erro ao contar notificações',
    );
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
