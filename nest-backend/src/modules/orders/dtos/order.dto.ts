import { z } from 'zod';

export const createOrderSchema = z.object({
  productId: z.string().uuid(),
});

export type CreateOrderDTO = z.infer<typeof createOrderSchema>;

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
