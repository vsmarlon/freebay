import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsInt,
  IsPositive,
  IsIn,
  IsEnum,
  IsArray,
  ArrayMaxSize,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { Condition } from '@prisma/client';
import { PRODUCT_SORTS, ProductSort } from '../types/product.types';

export class CreateProductDTO {
  @ApiProperty({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  @SanitizeText()
  readonly title: string;

  @ApiProperty({ example: 'Description of the product...', minLength: 10, maxLength: 5000 })
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  @SanitizeText()
  readonly description: string;

  @ApiProperty({ example: 150000, description: 'Price in cents (BRL)' })
  @Type(() => Number)
  @IsInt()
  @IsPositive()
  readonly price: number;

  @ApiProperty({ enum: Condition, example: Condition.USED })
  @IsEnum(Condition)
  readonly condition: Condition;

  @ApiProperty({ example: 'category-uuid' })
  @IsString()
  readonly categoryId: string;

  @ApiPropertyOptional({ example: ['https://example.com/img.jpg'], type: [String], maxItems: 10 })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(10)
  readonly images?: string[];

  @ApiPropertyOptional({ example: 5, description: 'Stock quantity (default 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly quantity?: number;
}

export class ProductQueryDTO {
  @ApiPropertyOptional({ description: 'Pagination cursor' })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;

  @ApiPropertyOptional({ description: 'Search query' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  readonly search?: string;

  @ApiPropertyOptional({ description: 'Category UUID filter' })
  @IsOptional()
  @IsString()
  readonly category?: string;

  @ApiPropertyOptional({ description: 'Minimum price in cents' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price in cents' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly maxPrice?: number;

  @ApiPropertyOptional({ enum: Condition })
  @IsOptional()
  @IsEnum(Condition)
  readonly condition?: Condition;

  @ApiPropertyOptional({ enum: PRODUCT_SORTS, default: 'recent' })
  @IsOptional()
  @IsIn(PRODUCT_SORTS)
  readonly sort?: ProductSort;
}

export class UpdateProductDTO {
  @ApiPropertyOptional({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  @SanitizeText()
  readonly title?: string;

  @ApiPropertyOptional({ example: 'Updated description', minLength: 10, maxLength: 5000 })
  @IsOptional()
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  @SanitizeText()
  readonly description?: string;

  @ApiPropertyOptional({ example: 150000, description: 'Price in cents (BRL)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @IsPositive()
  readonly price?: number;

  @ApiPropertyOptional({ enum: Condition, example: Condition.USED })
  @IsOptional()
  @IsEnum(Condition)
  readonly condition?: Condition;

  @ApiPropertyOptional({ enum: ['ACTIVE', 'PAUSED'], example: 'ACTIVE' })
  @IsOptional()
  @IsIn(['ACTIVE', 'PAUSED'])
  readonly status?: 'ACTIVE' | 'PAUSED';

  @ApiPropertyOptional({ example: 'category-uuid' })
  @IsOptional()
  @IsString()
  readonly categoryId?: string;

  @ApiPropertyOptional({ example: 5, description: 'Stock quantity (default 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  readonly quantity?: number;
}

export interface CreateProductInput {
  sellerId: string;
  title: string;
  description: string;
  price: number;
  condition: Condition;
  categoryId: string;
  images: string[];
  quantity?: number;
}

export interface CreateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: Condition;
  categoryId: string;
  sellerId: string;
  status: string;
  quantity: number;
  soldCount: number;
  createdAt: Date;
}

export interface DeleteProductInput {
  productId: string;
  userId: string;
}

export interface UpdateProductInput {
  productId: string;
  userId: string;
  title?: string;
  description?: string;
  price?: number;
  condition?: Condition;
  status?: 'ACTIVE' | 'PAUSED';
  categoryId?: string;
  quantity?: number;
}

export interface UpdateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: Condition;
  categoryId: string;
  sellerId: string;
  status: string;
  quantity: number;
  soldCount: number;
  createdAt: Date;
}

export interface DeleteProductOutput {
  deleted: boolean;
}
