import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@/shared/core/pagination';

export class CursorQueryDTO {
  @ApiPropertyOptional({
    description: 'Opaque cursor from a previous response. Omit for the first page.',
  })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({
    example: DEFAULT_PAGE_SIZE,
    description: `Page size, 1-${MAX_PAGE_SIZE}. Defaults to ${DEFAULT_PAGE_SIZE}.`,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_SIZE)
  readonly limit?: number;
}

export class CursorPageResponse {
  @ApiProperty({ example: true, description: 'Whether another page exists' })
  readonly hasMore!: boolean;

  @ApiPropertyOptional({
    example: 'eyJpZCI6ImFiYyJ9',
    nullable: true,
    description: 'Cursor for the next page, or null on the last page',
  })
  readonly nextCursor!: string | null;
}
