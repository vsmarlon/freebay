import { z } from 'zod';
import { isValidCpfOrCnpj } from '@/shared/utils/cpf.utils';

export const updateProfileSchema = z.object({
  displayName: z.string().min(2).max(50).optional(),
  bio: z.string().max(150).optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  avatarUrl: z.string().url().optional(),
  cpf: z.string().refine((v) => isValidCpfOrCnpj(v), 'CPF ou CNPJ inválido').optional(),
});

export const updateFcmTokenSchema = z.object({
  fcmToken: z.string().optional(),
  notificationPrefs: z.record(z.boolean()).optional(),
});

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>;
export type UpdateFcmTokenDTO = z.infer<typeof updateFcmTokenSchema>;

export interface GetProfileInput {
  userId: string;
}

export interface GetUserStatsInput {
  userId: string;
}

export interface UpdateProfileInput extends UpdateProfileDTO {
  userId: string;
}

export interface UpdateFcmTokenInput extends UpdateFcmTokenDTO {
  userId: string;
}

export interface FollowUserInput {
  followerId: string;
  followingId: string;
}

export interface BlockUserInput {
  blockerId: string;
  blockedId: string;
}

export interface SearchUsersInput {
  query: string;
  limit: number;
  cursor?: string;
}

export interface GetSuggestionsInput {
  userId: string;
  limit: number;
}
