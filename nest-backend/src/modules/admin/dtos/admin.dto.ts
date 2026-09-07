import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { ReportStatus } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { CursorQueryDTO } from '@/shared/dtos/pagination.dto';

export const RESOLVABLE_REPORT_STATUSES = ['REVIEWED', 'RESOLVED', 'REJECTED'] as const;
export type ResolvableReportStatus = (typeof RESOLVABLE_REPORT_STATUSES)[number];

export class AdminReportQueryDTO extends CursorQueryDTO {
  @ApiPropertyOptional({ enum: ReportStatus, description: 'Filter by report status' })
  @IsOptional()
  @IsIn(Object.values(ReportStatus))
  readonly status?: ReportStatus;
}

export class ResolveReportDTO {
  @ApiProperty({ enum: RESOLVABLE_REPORT_STATUSES })
  @IsIn(RESOLVABLE_REPORT_STATUSES)
  readonly status!: ResolvableReportStatus;

  @ApiPropertyOptional({ example: 'Anúncio removido por violar a política de itens proibidos' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  @SanitizeText()
  readonly note?: string;
}

export class SuspendUserDTO {
  @ApiProperty({ example: 'Reincidência em anúncios fraudulentos' })
  @IsString()
  @MinLength(5)
  @MaxLength(500)
  @SanitizeText()
  readonly reason!: string;
}

export class ModerationReasonDTO {
  @ApiPropertyOptional({ example: 'Conteúdo sexual explícito' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  @SanitizeText()
  readonly reason?: string;
}
