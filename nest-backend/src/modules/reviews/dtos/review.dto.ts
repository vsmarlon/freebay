import { IsUUID, IsInt, Min, Max, IsOptional, MaxLength, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ReviewType } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateReviewDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  reviewedId: string;

  @ApiProperty({ enum: ReviewType })
  @IsEnum(ReviewType)
  type: ReviewType;

  @ApiProperty({ example: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  score: number;

  @ApiPropertyOptional({ example: 'Great seller!', maxLength: 500 })
  @IsOptional()
  @MaxLength(500)
  @SanitizeText()
  comment?: string;
}

export class GetUserReviewsQueryDTO {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({ enum: ReviewType })
  @IsOptional()
  @IsEnum(ReviewType)
  type?: ReviewType;
}

export interface GetUserReviewsInput {
  userId: string;
  page?: number;
  limit?: number;
  type?: ReviewType;
}

export class ReviewResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  reviewerId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  reviewedId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  orderId: string;

  @ApiProperty({ enum: ReviewType })
  type: ReviewType;

  @ApiProperty({ example: 5 })
  score: number;

  @ApiPropertyOptional({ nullable: true })
  comment: string | null;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: string;

  @ApiProperty({ description: 'Reviewer details' })
  reviewer: Record<string, unknown>;
}

export interface GetUserReviewsOutput {
  reviews: ReviewResponse[];
  total: number;
  page: number;
  limit: number;
}

export interface CreateReviewInput {
  reviewerId: string;
  orderId: string;
  reviewedId: string;
  type: ReviewType;
  score: number;
  comment?: string;
}

export interface CreateReviewOutput {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: ReviewType;
  score: number;
  comment: string | null;
  createdAt: Date;
}
