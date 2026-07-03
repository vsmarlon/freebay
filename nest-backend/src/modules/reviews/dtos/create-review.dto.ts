import { IsUUID, IsInt, Min, Max, IsOptional, MaxLength, IsEnum, IsArray, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReviewType } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateReviewInput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly reviewedId: string;

  @ApiProperty({ enum: ReviewType })
  @IsEnum(ReviewType)
  readonly type: ReviewType;

  @ApiProperty({ example: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  readonly score: number;

  @ApiPropertyOptional({ example: 'Great seller!', maxLength: 500 })
  @IsOptional()
  @MaxLength(500)
  @SanitizeText()
  readonly comment?: string;

  @ApiPropertyOptional({ description: 'Uploaded image IDs to attach' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  readonly imageIds?: string[];
}
