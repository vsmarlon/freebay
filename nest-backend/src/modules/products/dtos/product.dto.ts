import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsInt,
  IsPositive,
  IsIn,
  IsEnum,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { Condition, ProductStatus } from '@prisma/client';
import { EDITABLE_PRODUCT_STATUSES, ProductSort } from '../types/product.types';
import { DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@/shared/core/pagination';

export const PRODUCT_TITLE_MIN_LENGTH = 3;
export const PRODUCT_TITLE_MAX_LENGTH = 100;
export const PRODUCT_DESCRIPTION_MIN_LENGTH = 10;
export const PRODUCT_DESCRIPTION_MAX_LENGTH = 5000;
export const PRODUCT_QUANTITY_MIN = 1;
export const PRODUCT_SEARCH_MAX_LENGTH = 200;

export class CreateProductDTO {
  @ApiProperty({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsString()
  @MinLength(PRODUCT_TITLE_MIN_LENGTH)
  @MaxLength(PRODUCT_TITLE_MAX_LENGTH)
  @SanitizeText()
  readonly title: string;

  @ApiProperty({ example: 'Description of the product...', minLength: PRODUCT_DESCRIPTION_MIN_LENGTH, maxLength: PRODUCT_DESCRIPTION_MAX_LENGTH })
  @IsString()
  @MinLength(PRODUCT_DESCRIPTION_MIN_LENGTH)
  @MaxLength(PRODUCT_DESCRIPTION_MAX_LENGTH)
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

  @ApiPropertyOptional({ example: 5, description: 'Stock quantity (default 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(PRODUCT_QUANTITY_MIN)
  readonly quantity?: number;
}

export class ProductQueryDTO {
  @ApiPropertyOptional({ description: 'Pagination cursor' })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({ example: DEFAULT_PAGE_SIZE })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_SIZE)
  readonly limit?: number;

  @ApiPropertyOptional({ description: 'Search query' })
  @IsOptional()
  @IsString()
  @MaxLength(PRODUCT_SEARCH_MAX_LENGTH)
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

  @ApiPropertyOptional({ enum: ProductSort, default: ProductSort.RECENT })
  @IsOptional()
  @IsIn(Object.values(ProductSort))
  readonly sort?: ProductSort;
}

export class UpdateProductDTO {
  @ApiPropertyOptional({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsOptional()
  @IsString()
  @MinLength(PRODUCT_TITLE_MIN_LENGTH)
  @MaxLength(PRODUCT_TITLE_MAX_LENGTH)
  @SanitizeText()
  readonly title?: string;

  @ApiPropertyOptional({ example: 'Updated description', minLength: PRODUCT_DESCRIPTION_MIN_LENGTH, maxLength: PRODUCT_DESCRIPTION_MAX_LENGTH })
  @IsOptional()
  @IsString()
  @MinLength(PRODUCT_DESCRIPTION_MIN_LENGTH)
  @MaxLength(PRODUCT_DESCRIPTION_MAX_LENGTH)
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

  @ApiPropertyOptional({ enum: EDITABLE_PRODUCT_STATUSES, example: ProductStatus.ACTIVE })
  @IsOptional()
  @IsIn(EDITABLE_PRODUCT_STATUSES)
  readonly status?: (typeof EDITABLE_PRODUCT_STATUSES)[number];

  @ApiPropertyOptional({ example: 'category-uuid' })
  @IsOptional()
  @IsString()
  readonly categoryId?: string;

  @ApiPropertyOptional({ example: 5, description: 'Stock quantity (default 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(PRODUCT_QUANTITY_MIN)
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
  imageBlurHash?: string;
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
  status: ProductStatus;
  quantity: number;
  soldCount: number;
  createdAt: Date;
  images: { id: string; url: string; order: number; productId: string; blurHash?: string }[];
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
  status?: (typeof EDITABLE_PRODUCT_STATUSES)[number];
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
  status: ProductStatus;
  quantity: number;
  soldCount: number;
  createdAt: Date;
}
