import { IsString, IsNotEmpty, IsUUID, MaxLength, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PushTestType } from '../types/push-delivery.types';

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

export class PushTestDTO {
  @ApiProperty({ required: false, example: 'Teste de push do FreeBay' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  readonly title?: string;

  @ApiProperty({ required: false, example: 'Se você recebeu isto, o envio push está funcionando.' })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(240)
  readonly body?: string;

  @ApiProperty({
    required: false,
    enum: PushTestType,
    description: 'Exercises the matching push preference; omitted sends without a category',
  })
  @IsOptional()
  @IsEnum(PushTestType)
  readonly type?: PushTestType;
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
