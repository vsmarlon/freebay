import { z } from 'zod';

export const createProductSchema = z.object({
  title: z.string().min(3).max(100),
  description: z.string().min(10).max(2000),
  price: z.number().int().positive(), // centavos
  condition: z.enum(['NEW', 'USED']),
});

export type CreateProductDTO = z.infer<typeof createProductSchema>;
