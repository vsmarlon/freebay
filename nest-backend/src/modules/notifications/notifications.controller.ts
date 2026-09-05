import { Controller, Body, Param, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, PatchAuth, CurrentUserId } from '@/shared/decorators';
import { GetNotificationsUseCase } from './usecases/get-notifications.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { MarkAllAsReadUseCase } from './usecases/mark-all-as-read.usecase';
import { RegisterFcmTokenUseCase } from './usecases/register-fcm-token.usecase';
import { RegisterFcmTokenDTO, NotificationResponse } from './dtos/notification.dto';
import { isLeft } from '@/shared/core/either';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly getNotificationsUseCase: GetNotificationsUseCase,
    private readonly markAsReadUseCase: MarkAsReadUseCase,
    private readonly markAllAsReadUseCase: MarkAllAsReadUseCase,
    private readonly registerFcmTokenUseCase: RegisterFcmTokenUseCase,
  ) {}

  @GetAuth({
    summary: 'Get notifications',
    responseType: NotificationResponse,
  })
  async findAll(@CurrentUserId() userId: string) {
    const result = await this.getNotificationsUseCase.execute(userId);
    if (isLeft(result)) return result;
    return { notifications: result.value };
  }

  @PostAuth('read-all', {
    summary: 'Mark all notifications as read',
    httpCode: HttpStatus.OK,
  })
  async markAllAsRead(@CurrentUserId() userId: string) {
    const result = await this.markAllAsReadUseCase.execute(userId);
    if (isLeft(result)) return result;
    return result.value;
  }

  @PostAuth('fcm-token', {
    summary: 'Register FCM token',
    bodyType: RegisterFcmTokenDTO,
  })
  async registerFcmToken(@CurrentUserId() userId: string, @Body() body: RegisterFcmTokenDTO) {
    const result = await this.registerFcmTokenUseCase.execute(userId, body.fcmToken);
    if (isLeft(result)) return result;
    return result.value;
  }

  @PatchAuth(':id/read', {
    summary: 'Mark notification as read',
    params: [{ name: 'id', description: 'Notification UUID' }],
    errors: [{ status: 404, description: 'Notification not found' }],
  })
  async markAsRead(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    const result = await this.markAsReadUseCase.execute(id, userId);
    if (isLeft(result)) return result;
    return result.value;
  }
}
