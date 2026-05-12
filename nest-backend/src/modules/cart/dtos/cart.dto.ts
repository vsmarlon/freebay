import { z } from 'zod';

export const checkoutCartSchema = z.object({});

export type CheckoutCartDTO = z.infer<typeof checkoutCartSchema>;

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
