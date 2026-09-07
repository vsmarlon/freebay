import { IsInt, Min, Max, IsOptional, IsIn } from 'class-validator';
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

export type CheckoutMode = 'session' | 'intent';

export class CheckoutCartDTO {
  @ApiPropertyOptional({
    enum: ['session', 'intent'],
    description:
      'session = hosted Stripe Checkout (web, PIX auto-offer, requires CPF). intent = PaymentSheet (mobile). Defaults to session.',
  })
  @IsOptional()
  @IsIn(['session', 'intent'])
  readonly mode?: CheckoutMode;
}

export interface CheckoutCartInput {
  userId: string;
  mode?: CheckoutMode;
}

export interface CheckoutCartItemOutput {
  orderId: string;
  productId: string;
  productTitle: string;
  quantity: number;
  amount: number;
}

export interface CheckoutCartOutput {
  paymentGroupId: string;
  items: CheckoutCartItemOutput[];
  totalOrders: number;
  totalAmount: number;
  checkoutUrl: string | null;
  paymentIntentClientSecret: string | null;
  expiresAt: Date | null;
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
}

export class CheckoutCartResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly paymentGroupId!: string;

  @ApiProperty({ type: [CheckoutCartItemResponse] })
  readonly items!: CheckoutCartItemResponse[];

  @ApiProperty({ example: 3 })
  readonly totalOrders!: number;

  @ApiProperty({ example: 45000 })
  readonly totalAmount!: number;

  @ApiPropertyOptional({
    example: 'https://checkout.stripe.com/pay/cs_test_abc123',
    nullable: true,
  })
  readonly checkoutUrl!: string | null;

  @ApiPropertyOptional({ example: 'pi_123_secret_456', nullable: true })
  readonly paymentIntentClientSecret!: string | null;

  @ApiPropertyOptional({ example: '2026-06-17T13:00:00.000Z', nullable: true })
  readonly expiresAt!: Date | null;
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

export interface AddToCartInput {
  userId: string;
  productId: string;
  quantity: number;
}

export interface AddToCartOutput {
  item: { id: string; quantity: number };
}

export interface GetCartOutput {
  items: Array<{
    id: string;
    productId: string;
    quantity: number;
    subtotal: number;
    product: CartItemProduct;
  }>;
  totalItems: number;
  totalPrice: number;
}

export interface RemoveFromCartInput {
  userId: string;
  productId: string;
}

export interface UpdateCartItemInput {
  userId: string;
  productId: string;
  quantity: number;
}

export interface UpdateCartItemOutput {
  item: { id: string; quantity: number };
}
