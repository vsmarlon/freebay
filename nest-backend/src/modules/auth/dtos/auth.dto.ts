import { z } from 'zod';

export const registerSchema = z.object({
  displayName: z.string().min(2).max(50),
  email: z.string().email(),
  password: z.string().min(8).max(100),
  city: z.string().optional(),
  state: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export type RegisterDTO = z.infer<typeof registerSchema>;
export type LoginDTO = z.infer<typeof loginSchema>;
