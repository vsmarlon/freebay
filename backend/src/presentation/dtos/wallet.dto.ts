import { z } from 'zod';

export const withdrawSchema = z.object({
  amount: z.number().positive(),
});

export type WithdrawDTO = z.infer<typeof withdrawSchema>;
