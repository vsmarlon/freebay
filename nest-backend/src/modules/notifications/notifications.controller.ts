import { Controller, Get, Post, Body, Param, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { GetNotificationsUseCase } from './usecases/get-notifications.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { MarkAllAsReadUseCase } from './usecases/mark-all-as-read.usecase';
import { RegisterFcmTokenUseCase } from './usecases/register-fcm-token.usecase';
import { RegisterFcmTokenDTO, NotificationResponse } from './dtos/notification.dto';
import { isLeft } from '@/shared/core/either';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(
    private readonly getNotificationsUseCase: GetNotificationsUseCase,
    private readonly markAsReadUseCase: MarkAsReadUseCase,
    private readonly markAllAsReadUseCase: MarkAllAsReadUseCase,
    private readonly registerFcmTokenUseCase: RegisterFcmTokenUseCase,
  ) {}

  @Get()
  @ApiDoc({
    summary: 'Get notifications',
    auth: true,
    responseType: NotificationResponse,
  })
  async findAll(@CurrentUser() user: AuthUser) {
    const result = await this.getNotificationsUseCase.execute(user.userId);
    if (isLeft(result)) return result;
    return { notifications: result.value };
  }

  @Post(':id/read')
  @ApiDoc({
    summary: 'Mark notification as read',
    auth: true,
    params: [{ name: 'id', description: 'Notification UUID' }],
    errors: [{ status: 404, description: 'Notification not found' }],
  })
  async markAsRead(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.markAsReadUseCase.execute(id, user.userId);
    if (isLeft(result)) return result;
    return result.value;
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Mark all notifications as read',
    auth: true,
  })
  async markAllAsRead(@CurrentUser() user: AuthUser) {
    const result = await this.markAllAsReadUseCase.execute(user.userId);
    if (isLeft(result)) return result;
    return result.value;
  }

  @Post('fcm-token')
  @ApiDoc({
    summary: 'Register FCM token',
    auth: true,
    bodyType: RegisterFcmTokenDTO,
  })
  async registerFcmToken(@CurrentUser() user: AuthUser, @Body() body: RegisterFcmTokenDTO) {
    const result = await this.registerFcmTokenUseCase.execute(user.userId, body.fcmToken);
    if (isLeft(result)) return result;
    return result.value;
  }
}
