import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { GetNotificationsUseCase, MarkAsReadUseCase, RegisterFcmTokenUseCase } from './usecases/notification.usecase';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

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
  async findAll(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.getNotificationsUseCase.execute(userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { notifications: result.value };
  }

  @Post(':id/read')
  async markAsRead(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.markAsReadUseCase.execute(id, user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('fcm-token')
  async registerFcmToken(@CurrentUser() user: AuthUser, @Body() body: { fcmToken: string }) {
    const result = await this.registerFcmTokenUseCase.execute(user.userId, body.fcmToken);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('read-all')
  async markAllAsRead(@CurrentUser() user: AuthUser) {
    await this.prisma.notification.updateMany({
      where: { userId: user.userId, read: false },
      data: { read: true },
    });
    return { marked: true };
  }
}
