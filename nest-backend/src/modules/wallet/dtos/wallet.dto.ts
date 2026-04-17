import { z } from 'zod';

export const withdrawSchema = z.object({
  amount: z.number().int().positive(),
  pixKey: z.string().min(1),
  pixKeyType: z.enum(['CPF', 'EMAIL', 'PHONE', 'RANDOM']),
});

export type WithdrawDTO = z.infer<typeof withdrawSchema>;

export interface GetWalletOutput {
  balance: number;
  pendingBalance: number;
  availableBalance: number;
}

export interface WithdrawInput {
  userId: string;
  amount: number;
  pixKey: string;
  pixKeyType: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM';
}
