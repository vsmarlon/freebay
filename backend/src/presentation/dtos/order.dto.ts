import { z } from 'zod';

export const createOrderSchema = z.object({
  productId: z.string().uuid(),
});

export const processPaymentSchema = z.object({
  orderId: z.string().uuid(),
  paymentMethod: z.enum(['PIX', 'CREDIT_CARD']),
  provider: z.enum(['PAGARME', 'WOOVI']).optional().default('PAGARME'),
});

export type CreateOrderDTO = z.infer<typeof createOrderSchema>;
export type ProcessPaymentDTO = z.infer<typeof processPaymentSchema>;
