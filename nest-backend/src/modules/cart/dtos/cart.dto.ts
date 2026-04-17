import { z } from 'zod';

export const checkoutCartSchema = z.object({
  customerName: z.string().min(1),
  customerTaxId: z.string().min(11).max(14),
  customerEmail: z.string().email(),
});

export type CheckoutCartDTO = z.infer<typeof checkoutCartSchema>;

export interface CheckoutCartInput {
  userId: string;
  customerName: string;
  customerTaxId: string;
  customerEmail: string;
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
