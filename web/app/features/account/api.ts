import { api } from '../../core/api';
import type { User } from './account';

export type Profile = User & { cpf?: string | null; phone?: string | null };
export type Stats = Partial<{ followersCount: number; followingCount: number }>;
export type PeoplePage = { users: User[]; hasMore: boolean; nextOffset: number | null };

export const accountApi = {
  me: (signal?: AbortSignal) => api.get<Profile>('/users/me', { signal }),
  user: (id: string, signal?: AbortSignal) =>
    api.get<User>(`/users/${encodeURIComponent(id)}`, { auth: false, signal }),
  stats: (signal?: AbortSignal) => api.get<Stats>('/users/me/stats', { signal }),
  totals: async (id: string, signal?: AbortSignal): Promise<Stats> => {
    const [followers, following] = await Promise.all([
      api.get<{ total: number }>(`/users/${encodeURIComponent(id)}/followers?limit=1&offset=0`, {
        auth: false,
        signal,
      }),
      api.get<{ total: number }>(`/users/${encodeURIComponent(id)}/following?limit=1&offset=0`, {
        auth: false,
        signal,
      }),
    ]);
    return { followersCount: followers.total, followingCount: following.total };
  },
  isFollowing: (id: string, signal?: AbortSignal) =>
    api.get<{ isFollowing: boolean }>(`/users/${encodeURIComponent(id)}/is-following`, { signal }),
  isBlocked: (id: string, signal?: AbortSignal) =>
    api.get<{ isBlocked: boolean }>(`/users/${encodeURIComponent(id)}/is-blocked`, { signal }),
  follow: (id: string) =>
    api.post<{ followersCount: number }>(`/users/${encodeURIComponent(id)}/follow`),
  unfollow: (id: string) =>
    api.patch<{ followersCount: number }>(`/users/${encodeURIComponent(id)}/unfollow`),
  block: (id: string) => api.post(`/users/${encodeURIComponent(id)}/block`),
  unblock: (id: string) => api.patch(`/users/${encodeURIComponent(id)}/unblock`),
  restrict: (id: string) => api.post(`/users/me/restricted/${encodeURIComponent(id)}`),
  reportUser: (input: { targetId: string; reason: string; description?: string }) =>
    api.post('/reports', { targetType: 'USER', ...input }),
  updateProfile: (payload: Record<string, unknown>) => api.patch<Profile>('/users/me', payload),
  uploadImage: (kind: 'avatar' | 'banner', body: FormData) =>
    api.post<Profile>(`/users/me/${kind}`, body),
  requestProfileVerification: (cpf: string, locale: string) =>
    api.post<{ expiresIn: number; resendAfter: number }>('/users/me/profile-verification', {
      cpf,
      locale,
    }),
  setPhone: (phone: string) => api.post('/users/me/phone', { phone }),
  verifyPhone: (code: string) => api.post('/users/me/phone/verify', { code }),
  searchPeople: (query: string, offset: number) =>
    api.get<PeoplePage>(
      `/users/search?q=${encodeURIComponent(query.trim())}&limit=20&offset=${offset}`,
    ),
  exportData: (stepUpToken: string) =>
    api.get<unknown>('/users/me/export', { headers: { 'x-step-up-token': stepUpToken } }),
  requestDeletion: (stepUpToken: string) =>
    api.delete<{ purgeAfter: string }>('/users/me/web', {
      headers: { 'x-step-up-token': stepUpToken },
    }),
  cancelDeletion: () => api.patch('/users/me/web/deletion/cancel'),
  sendBugReport: (input: {
    description: string;
    appVersion: string;
    platform: string;
    screenContext: string;
  }) => api.post('/bug-reports', input),
};
