import { IsInt, Min, Max, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AddToCartDTO {
  @ApiPropertyOptional({ example: 1, description: 'Quantity (1-10, default 1)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  quantity?: number;
}

export class UpdateCartItemDTO {
  @ApiProperty({ example: 3 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  quantity: number;
}

export interface CheckoutCartInput {
  userId: string;
}

export interface CheckoutCartItemOutput {
  orderId: string;
  productId: string;
  productTitle: string;
  quantity: number;
  amount: number;
  pixQrCode: string;
  pixImage: string;
  expiresAt: Date;
}

export interface CheckoutCartOutput {
  items: CheckoutCartItemOutput[];
  totalOrders: number;
  totalAmount: number;
}

export class CheckoutCartItemResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  orderId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  productId: string;

  @ApiProperty({ example: 'iPhone 15' })
  productTitle: string;

  @ApiProperty({ example: 1 })
  quantity: number;

  @ApiProperty({ example: 15000 })
  amount: number;

  @ApiProperty({ example: '00020126580014BR.GOV.BCB.PIX...' })
  pixQrCode: string;

  @ApiProperty({ example: 'data:image/png;base64,...' })
  pixImage: string;

  @ApiProperty({ example: '2026-06-17T13:00:00.000Z' })
  expiresAt: Date;
}

export class CheckoutCartResponse {
  @ApiProperty({ type: [CheckoutCartItemResponse] })
  items: CheckoutCartItemResponse[];

  @ApiProperty({ example: 3 })
  totalOrders: number;

  @ApiProperty({ example: 45000 })
  totalAmount: number;
}

export class CartItemResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  productId: string;

  @ApiProperty({ example: 2 })
  quantity: number;

  @ApiProperty({ example: 30000 })
  subtotal: number;

  product: unknown;
}

export class CartResponse {
  @ApiProperty({ type: [CartItemResponse] })
  items: CartItemResponse[];

  @ApiProperty({ example: 5 })
  totalItems: number;

  @ApiProperty({ example: 75000 })
  totalPrice: number;
}
