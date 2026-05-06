import { z } from 'zod';

export const requestPasswordRecoverySchema = z.object({
  email: z.string().email(),
});

export const verifyPasswordRecoveryCodeSchema = z.object({
  email: z.string().email(),
  code: z.string().regex(/^\d{6}$/, 'Código deve ter 6 dígitos'),
});

export const resetPasswordSchema = z.object({
  email: z.string().email(),
  code: z.string().regex(/^\d{6}$/, 'Código deve ter 6 dígitos'),
  newPassword: z.string().min(8).max(100),
});

export type RequestPasswordRecoveryDTO = z.infer<typeof requestPasswordRecoverySchema>;
export type VerifyPasswordRecoveryCodeDTO = z.infer<typeof verifyPasswordRecoveryCodeSchema>;
export type ResetPasswordDTO = z.infer<typeof resetPasswordSchema>;
