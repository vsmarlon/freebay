import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsInt,
  IsPositive,
  IsIn,
  IsArray,
  ArrayMaxSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreateProductDTO {
  @ApiProperty({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  @SanitizeText()
  title: string;

  @ApiProperty({ example: 'Description of the product...', minLength: 10, maxLength: 5000 })
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  @SanitizeText()
  description: string;

  @ApiProperty({ example: 150000, description: 'Price in cents (BRL)' })
  @Type(() => Number)
  @IsInt()
  @IsPositive()
  price: number;

  @ApiProperty({ enum: ['NEW', 'USED'], example: 'USED' })
  @IsIn(['NEW', 'USED'])
  condition: 'NEW' | 'USED';

  @ApiProperty({ example: 'category-uuid' })
  @IsString()
  categoryId: string;

  @ApiPropertyOptional({ example: ['https://example.com/img.jpg'], type: [String], maxItems: 10 })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(10)
  images?: string[];
}

export class UpdateProductDTO {
  @ApiPropertyOptional({ example: 'iPhone 12', minLength: 3, maxLength: 100 })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  @SanitizeText()
  title?: string;

  @ApiPropertyOptional({ example: 'Updated description', minLength: 10, maxLength: 5000 })
  @IsOptional()
  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  @SanitizeText()
  description?: string;

  @ApiPropertyOptional({ example: 150000, description: 'Price in cents (BRL)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @IsPositive()
  price?: number;

  @ApiPropertyOptional({ enum: ['NEW', 'USED'], example: 'USED' })
  @IsOptional()
  @IsIn(['NEW', 'USED'])
  condition?: 'NEW' | 'USED';

  @ApiPropertyOptional({ enum: ['ACTIVE', 'PAUSED'], example: 'ACTIVE' })
  @IsOptional()
  @IsIn(['ACTIVE', 'PAUSED'])
  status?: 'ACTIVE' | 'PAUSED';

  @ApiPropertyOptional({ example: 'category-uuid' })
  @IsOptional()
  @IsString()
  categoryId?: string;
}

export interface CreateProductInput {
  sellerId: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  images: string[];
}

export interface CreateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  sellerId: string;
  status: string;
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
  condition?: 'NEW' | 'USED';
  status?: 'ACTIVE' | 'PAUSED';
  categoryId?: string;
}

export interface UpdateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  sellerId: string;
  status: string;
  createdAt: Date;
}

export interface DeleteProductOutput {
  deleted: boolean;
}
