import { z } from 'zod';

export const createPixPaymentSchema = z.object({
  customerName: z.string().min(1),
  customerTaxId: z.string().min(11).max(14),
  customerEmail: z.string().email(),
});

export type CreatePixPaymentDTO = z.infer<typeof createPixPaymentSchema>;

export interface CreatePixPaymentInput {
  orderId: string;
  userId: string;
  customerName: string;
  customerTaxId: string;
  customerEmail: string;
  idempotencyKey?: string;
}

export interface CreatePixPaymentOutput {
  orderId: string;
  pixQrCode: string;
  pixImage: string;
  expiresAt: Date;
}

export interface ProcessWebhookInput {
  event: string;
  data: unknown;
}

export interface ProcessWebhookOutput {
  processed: boolean;
}

export interface CreateWithdrawalInput {
  withdrawalId: string;
}

export interface CreateWithdrawalOutput {
  transferred: boolean;
}
