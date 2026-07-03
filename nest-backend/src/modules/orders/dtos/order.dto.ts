import { IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateOrderDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly productId: string;
}

export class OrderResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly buyerId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly sellerId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly productId: string;

  @ApiProperty({ example: 15000 })
  readonly amount: number;

  @ApiProperty({ example: 'PENDING' })
  readonly status: string;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  readonly createdAt: Date;
}

export interface CreateOrderInput {
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  platformFeePercent: number;
}

export interface CreateOrderOutput {
  id: string;
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  status: string;
  createdAt: Date;
}

export interface ConfirmDeliveryInput {
  orderId: string;
  buyerId: string;
}

export class MarkAsShippedDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly orderId: string;
}

export class MarkAsDeliveredDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly orderId: string;
}

export class CancelOrderDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly orderId: string;
}

export interface MarkAsShippedInput {
  orderId: string;
  sellerId: string;
}

export interface MarkAsDeliveredInput {
  orderId: string;
  buyerId: string;
}

export interface CancelOrderInput {
  orderId: string;
  userId: string;
}
