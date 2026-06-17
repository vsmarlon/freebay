import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { GetNotificationsUseCase, MarkAsReadUseCase, RegisterFcmTokenUseCase } from './usecases/notification.usecase';
import { RegisterFcmTokenDTO, NotificationResponse } from './dtos/notification.dto';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private prisma: PrismaService,
    private getNotificationsUseCase: GetNotificationsUseCase,
    private markAsReadUseCase: MarkAsReadUseCase,
    private registerFcmTokenUseCase: RegisterFcmTokenUseCase,
  ) {}

  @Get()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get notifications',
    auth: true,
    responseType: NotificationResponse,
  })
  async findAll(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.getNotificationsUseCase.execute(userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { notifications: result.value };
  }

  @Post(':id/read')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Mark notification as read',
    auth: true,
    params: [{ name: 'id', description: 'Notification UUID' }],
    errors: [{ status: 404, description: 'Notification not found' }],
  })
  async markAsRead(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.markAsReadUseCase.execute(id, user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('fcm-token')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Register FCM token',
    auth: true,
    bodyType: RegisterFcmTokenDTO,
  })
  async registerFcmToken(@CurrentUser() user: AuthUser, @Body() body: RegisterFcmTokenDTO) {
    const result = await this.registerFcmTokenUseCase.execute(user.userId, body.fcmToken);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('read-all')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Mark all notifications as read',
    auth: true,
  })
  async markAllAsRead(@CurrentUser() user: AuthUser) {
    await this.prisma.notification.updateMany({
      where: { userId: user.userId, read: false },
      data: { read: true },
    });
    return { marked: true };
  }
}
