import { IsUUID, IsOptional, IsEnum, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { ReportReason, ReportTargetType } from '@prisma/client';

export class CreateReportDTO {
  @ApiProperty({ enum: ReportTargetType })
  @IsEnum(ReportTargetType)
  readonly targetType: ReportTargetType;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly targetId: string;

  @ApiProperty({ enum: ReportReason, example: ReportReason.SPAM })
  @IsEnum(ReportReason)
  @SanitizeText()
  readonly reason: ReportReason;

  @ApiPropertyOptional({ example: 'Usuário está enviando mensagens de spam' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  @SanitizeText()
  readonly description?: string;
}

export interface CreateReportInput {
  reporterId: string;
  targetType: ReportTargetType;
  targetId: string;
  reason: ReportReason;
  description?: string;
}
