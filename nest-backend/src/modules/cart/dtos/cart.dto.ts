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
  readonly quantity?: number;
}

export class UpdateCartItemDTO {
  @ApiProperty({ example: 3 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10)
  readonly quantity!: number;
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
  readonly orderId!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly productId!: string;

  @ApiProperty({ example: 'iPhone 15' })
  readonly productTitle!: string;

  @ApiProperty({ example: 1 })
  readonly quantity!: number;

  @ApiProperty({ example: 15000 })
  readonly amount!: number;

  @ApiProperty({ example: '00020126580014BR.GOV.BCB.PIX...' })
  readonly pixQrCode!: string;

  @ApiProperty({ example: 'data:image/png;base64,...' })
  readonly pixImage!: string;

  @ApiProperty({ example: '2026-06-17T13:00:00.000Z' })
  readonly expiresAt!: Date;
}

export class CheckoutCartResponse {
  @ApiProperty({ type: [CheckoutCartItemResponse] })
  readonly items!: CheckoutCartItemResponse[];

  @ApiProperty({ example: 3 })
  readonly totalOrders!: number;

  @ApiProperty({ example: 45000 })
  readonly totalAmount!: number;
}

export class CartItemResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly productId!: string;

  @ApiProperty({ example: 2 })
  readonly quantity!: number;

  @ApiProperty({ example: 30000 })
  readonly subtotal!: number;

  readonly product!: CartItemProduct;
}

export interface CartItemProduct {
  id: string;
  title: string;
  price: number;
  sellerId: string;
  images: { id: string; url: string }[];
  seller: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
}

export class CartResponse {
  @ApiProperty({ type: [CartItemResponse] })
  readonly items!: CartItemResponse[];

  @ApiProperty({ example: 5 })
  readonly totalItems!: number;

  @ApiProperty({ example: 75000 })
  readonly totalPrice!: number;
}
