import { IsString, MinLength, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateBugReportDTO {
  @ApiProperty({ example: 'O app fecha ao tentar abrir o carrinho' })
  @IsString()
  @MinLength(1)
  @SanitizeText()
  readonly description!: string;

  @ApiPropertyOptional({ example: '1.4.2' })
  @IsOptional()
  @IsString()
  readonly appVersion?: string;

  @ApiPropertyOptional({ example: 'android' })
  @IsOptional()
  @IsString()
  readonly platform?: string;

  @ApiPropertyOptional({ example: '/chat/list' })
  @IsOptional()
  @IsString()
  readonly screenContext?: string;
}

export class BugReportResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id!: string;

  @ApiProperty({ example: 'O app fecha ao tentar abrir o carrinho' })
  readonly description!: string;

  @ApiProperty()
  readonly createdAt!: Date;
}

export interface CreateBugReportInput {
  userId: string;
  description: string;
  appVersion?: string;
  platform?: string;
  screenContext?: string;
}
