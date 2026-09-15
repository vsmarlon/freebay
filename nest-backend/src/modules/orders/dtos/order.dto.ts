import { IsIn, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { EscrowStatus, OrderStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { CursorQueryDTO } from '@/shared/dtos/pagination.dto';
import { SALES_ORDER_STATUSES, SalesOrderStatus } from '../types/order.types';

export class CreateOrderDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  readonly productId: string;
}

export interface CreateOrderInput {
  buyerId: string;
  productId: string;
  platformFeePercent: number;
  sellerId?: string;
  amount?: number;
}

export class SalesOrdersQueryDTO extends CursorQueryDTO {
  @ApiProperty({ enum: SALES_ORDER_STATUSES, required: false })
  @IsOptional()
  @IsIn([...SALES_ORDER_STATUSES])
  @Type(() => String)
  readonly status?: SalesOrderStatus;
}

export interface CreateOrderOutput {
  id: string;
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  platformFee: number;
  sellerAmount: number;
  status: OrderStatus;
  escrowStatus: EscrowStatus;
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
