import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { Notification, Prisma } from '@prisma/client';

@Injectable()
export class NotificationDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findByUserId(
    userId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<Notification>> {
    return repositoryResponse(
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
    return repositoryResponse(() => this.prisma.notification.findUnique({
      where: { id },
    }), 'Failed to fetch notification');
  }

  async countUnread(userId: string): RepositoryResponse<number> {
    return repositoryResponse(
      () => this.prisma.notification.count({ where: { userId, read: false } }),
      'Erro ao contar notificações',
    );
  }

  async markAsRead(id: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.notification.update({ where: { id }, data: { read: true } });
    }, 'Failed to mark notification as read');
  }

  async markAllAsRead(userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.notification.updateMany({ where: { userId, read: false }, data: { read: true } });
    }, 'Failed to mark all notifications as read');
  }

  async updatePushSettings(userId: string, input: {
    installationId?: string;
    fcmToken?: string | null;
    notificationPrefs?: Record<string, boolean>;
  }): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.$transaction(async (tx) => {
        if (input.installationId && input.fcmToken !== undefined) {
          if (input.fcmToken === null) {
            await tx.pushDevice.deleteMany({ where: { userId, installationId: input.installationId } });
          } else {
            await tx.pushDevice.deleteMany({ where: { token: input.fcmToken, installationId: { not: input.installationId } } });
            await tx.pushDevice.upsert({
              where: { installationId: input.installationId },
              create: { installationId: input.installationId, userId, token: input.fcmToken },
              update: { userId, token: input.fcmToken },
            });
          }
        }
        const data: Prisma.UserUpdateInput = {};
        if (input.fcmToken !== undefined) data.fcmToken = null;
        if (input.notificationPrefs !== undefined) {
          const current = await tx.user.findUniqueOrThrow({ where: { id: userId }, select: { notificationPrefs: true } });
          const prefs = current.notificationPrefs;
          data.notificationPrefs = { ...(prefs && typeof prefs === 'object' && !Array.isArray(prefs) ? prefs : {}), ...input.notificationPrefs };
        }
        if (Object.keys(data).length) await tx.user.update({ where: { id: userId }, data });
      });
    }, 'Failed to update push settings');
  }

  removePushDevice(userId: string, installationId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.pushDevice.deleteMany({ where: { userId, installationId } });
    }, 'Failed to unregister push device');
  }

  findPushTargets(userId: string) {
    return repositoryResponse(() => this.prisma.user.findUnique({
      where: { id: userId },
      select: { notificationPrefs: true, deletedAt: true, deletionRequestedAt: true, pushDevices: { select: { token: true } } },
    }), 'Failed to fetch push targets');
  }

  removeInvalidPushTokens(userId: string, tokens: string[]): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.pushDevice.deleteMany({ where: { userId, token: { in: tokens } } });
    }, 'Failed to remove invalid push tokens');
  }
}
