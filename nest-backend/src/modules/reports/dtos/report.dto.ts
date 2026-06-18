import { IsUUID, IsString, MinLength, IsOptional, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Report, ReportReason } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateReportDTO {
  @ApiProperty({ enum: ['USER', 'POST'] })
  @IsIn(['USER', 'POST'])
  targetType: 'USER' | 'POST';

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  targetId: string;

  @ApiProperty({ example: 'SPAM' })
  @IsString()
  @MinLength(1)
  @SanitizeText()
  reason: string;

  @ApiPropertyOptional({ example: 'Usuário está enviando mensagens de spam' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  description?: string;
}

export class ResolveReportDTO {
  @ApiProperty({ enum: ['REVIEWED', 'RESOLVED', 'REJECTED'] })
  @IsIn(['REVIEWED', 'RESOLVED', 'REJECTED'])
  status: 'REVIEWED' | 'RESOLVED' | 'REJECTED';

  @ApiPropertyOptional({ example: 'Report reviewed and action taken' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  adminNote?: string;
}

export class GetReportsQueryDTO {
  @ApiPropertyOptional({ enum: ['PENDING', 'REVIEWED', 'RESOLVED', 'REJECTED'] })
  @IsOptional()
  @IsIn(['PENDING', 'REVIEWED', 'RESOLVED', 'REJECTED'])
  status?: 'PENDING' | 'REVIEWED' | 'RESOLVED' | 'REJECTED';
}

export class ResolveReportOutput {
  @ApiProperty({ example: true })
  resolved: boolean;
}

export interface CreateReportInput {
  reporterId: string;
  targetType: 'USER' | 'POST';
  targetId: string;
  reason: string;
  description?: string;
}

export interface GetReportsInput {
  status?: string;
}

export interface ResolveReportInput {
  reportId: string;
  status: 'REVIEWED' | 'RESOLVED' | 'REJECTED';
  adminNote?: string;
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
