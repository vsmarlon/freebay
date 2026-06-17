import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Notification } from '@prisma/client';

export class RegisterFcmTokenDTO {
  @ApiProperty({ example: 'fcm-token-abc123' })
  @IsString()
  @IsNotEmpty()
  fcmToken: string;
}

export class NotificationResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'USER_ID' })
  userId: string;

  @ApiProperty({ example: 'Você recebeu uma nova mensagem' })
  content: string;

  @ApiProperty({ example: false })
  read: boolean;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: Date;
}

export interface GetNotificationsInput {
  userId: string;
  limit?: number;
}

export type GetNotificationsOutput = Notification[];

export interface MarkAsReadInput {
  notificationId: string;
  userId: string;
}

export interface RegisterFcmTokenInput {
  userId: string;
  fcmToken: string;
}
