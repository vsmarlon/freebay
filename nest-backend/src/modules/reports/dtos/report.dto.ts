import { IsUUID, IsString, MinLength, IsOptional, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Report, ReportReason } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateReportDTO {
  @ApiProperty({ enum: ['USER', 'POST', 'CONVERSATION', 'MESSAGE', 'ORDER_CHAT', 'CHAT_MESSAGE'] })
  @IsIn(['USER', 'POST', 'CONVERSATION', 'MESSAGE', 'ORDER_CHAT', 'CHAT_MESSAGE'])
  readonly targetType: 'USER' | 'POST' | 'CONVERSATION' | 'MESSAGE' | 'ORDER_CHAT' | 'CHAT_MESSAGE';

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly targetId: string;

  @ApiProperty({ example: 'SPAM' })
  @IsString()
  @MinLength(1)
  @SanitizeText()
  readonly reason: string;

  @ApiPropertyOptional({ example: 'Usuário está enviando mensagens de spam' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly description?: string;
}

export class ResolveReportDTO {
  @ApiProperty({ enum: ['REVIEWED', 'RESOLVED', 'REJECTED'] })
  @IsIn(['REVIEWED', 'RESOLVED', 'REJECTED'])
  readonly status: 'REVIEWED' | 'RESOLVED' | 'REJECTED';

  @ApiPropertyOptional({ example: 'Report reviewed and action taken' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly adminNote?: string;
}

export class GetReportsQueryDTO {
  @ApiPropertyOptional({ enum: ['PENDING', 'REVIEWED', 'RESOLVED', 'REJECTED'] })
  @IsOptional()
  @IsIn(['PENDING', 'REVIEWED', 'RESOLVED', 'REJECTED'])
  readonly status?: 'PENDING' | 'REVIEWED' | 'RESOLVED' | 'REJECTED';
}

export interface CreateReportInput {
  reporterId: string;
  targetType: 'USER' | 'POST' | 'CONVERSATION' | 'MESSAGE' | 'ORDER_CHAT' | 'CHAT_MESSAGE';
  targetId: string;
  reason: string;
  description?: string;
}

export interface ReportWithRelations {
  id: string;
  reason: ReportReason;
  description: string | null;
  status: Report['status'];
  createdAt: Date;
  reporterId: string;
  reportedUserId: string | null;
  reportedPostId: string | null;
}
