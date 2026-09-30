import { Controller, Body, Param, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  CurrentUserId,
  Paginated,
  PAGINATION_QUERIES,
} from '@/shared/decorators';
import { PageQuery } from '@/shared/core/pagination';
import { GetNotificationsUseCase } from './usecases/get-notifications.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { MarkAllAsReadUseCase } from './usecases/mark-all-as-read.usecase';
import { RegisterFcmTokenUseCase } from './usecases/register-fcm-token.usecase';
import { RegisterFcmTokenDTO, NotificationResponse } from './dtos/notification.dto';
import { NotificationDatabaseRepository } from './data/repositories/notification-database.repository';
;

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly getNotificationsUseCase: GetNotificationsUseCase,
    private readonly markAsReadUseCase: MarkAsReadUseCase,
    private readonly markAllAsReadUseCase: MarkAllAsReadUseCase,
    private readonly registerFcmTokenUseCase: RegisterFcmTokenUseCase,
    private readonly notificationRepository: NotificationDatabaseRepository,
  ) {}

  @GetAuth({
    summary: 'Get notifications',
    description: 'Cursor-paginated, newest first',
    responseType: NotificationResponse,
    queries: PAGINATION_QUERIES,
  })
  async findAll(@CurrentUserId() userId: string, @Paginated() page: PageQuery) {
    return this.getNotificationsUseCase.execute(userId, page);
  }

  @GetAuth('unread-count', {
    summary: 'Count unread notifications',
  })
  async countUnread(@CurrentUserId() userId: string) {
    const result = await this.notificationRepository.countUnread(userId);
    if (result.isLeft()) return result;
    return { count: result.value };
  }

  @PostAuth('read-all', {
    summary: 'Mark all notifications as read',
    httpCode: HttpStatus.OK,
  })
  async markAllAsRead(@CurrentUserId() userId: string) {
    return this.markAllAsReadUseCase.execute(userId);
  }

  @PostAuth('fcm-token', {
    summary: 'Register FCM token',
    bodyType: RegisterFcmTokenDTO,
  })
  async registerFcmToken(@CurrentUserId() userId: string, @Body() body: RegisterFcmTokenDTO) {
    return this.registerFcmTokenUseCase.execute(userId, body.fcmToken, body.installationId);
  }

  @PatchAuth(':id/read', {
    summary: 'Mark notification as read',
    params: [{ name: 'id', description: 'Notification UUID' }],
    errors: [{ status: 404, description: 'Notification not found' }],
  })
  async markAsRead(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.markAsReadUseCase.execute(id, userId);
  }
}
