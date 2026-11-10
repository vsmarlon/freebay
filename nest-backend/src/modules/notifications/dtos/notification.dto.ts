import { IsString, IsNotEmpty, IsUUID, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterFcmTokenDTO {
  @ApiProperty({ example: 'fcm-token-abc123' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  readonly fcmToken: string;

  @ApiProperty({ description: 'Stable UUID of this app installation' })
  @IsUUID('4')
  readonly installationId: string;
}

export class NotificationResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id: string;

  @ApiProperty({ example: 'USER_ID' })
  readonly userId: string;

  @ApiProperty({ example: 'Você recebeu uma nova mensagem' })
  readonly content: string;

  @ApiProperty({ example: false })
  readonly read: boolean;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  readonly createdAt: Date;
}
