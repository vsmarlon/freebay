import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { FcmService } from './fcm.service';
import {
  GetNotificationsUseCase,
  MarkAsReadUseCase,
  RegisterFcmTokenUseCase,
} from './usecases/notification.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsGateway,
    FcmService,
    GetNotificationsUseCase,
    MarkAsReadUseCase,
    RegisterFcmTokenUseCase,
    PrismaService,
  ],
})
export class NotificationsModule {}
