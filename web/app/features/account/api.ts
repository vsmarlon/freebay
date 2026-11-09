import { api } from '../../core/api';
import type { User } from './account';

export type Profile = User & {
  cpf?: string | null;
  phone?: string | null;
  notificationPrefs?: unknown;
};
export type Stats = Partial<{ followersCount: number; followingCount: number }>;
export type PeoplePage = { users: User[]; hasMore: boolean; nextOffset: number | null };
export type UsersResponse = { users?: User[] } | User[];

export const usersFrom = (result: UsersResponse): User[] =>
  Array.isArray(result) ? result : (result.users ?? []);

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
  saveNotificationPreference: (key: string, enabled: boolean) =>
    api.patch('/users/me/fcm-token', { notificationPrefs: { [key]: enabled } }),
  cancelDeletion: () => api.patch('/users/me/web/deletion/cancel'),
  sendBugReport: (input: {
    description: string;
    appVersion: string;
    platform: string;
    screenContext: string;
  }) => api.post('/bug-reports', input),
};

export const PAGE_SIZE = 20;
export type FollowState = boolean | null;
type ConnectionsResponse = { users?: User[]; items?: User[] } | User[];

export const connectionsApi = {
  async list(endpoint: string, offset: number, signal?: AbortSignal): Promise<User[]> {
    const result = await api.get<ConnectionsResponse>(
      `${endpoint}?limit=${PAGE_SIZE}&offset=${offset}`,
      { signal },
    );
    return Array.isArray(result) ? result : (result.users ?? result.items ?? []);
  },
  /** Follow state per listed person; `null` means unknown, which keeps the button disabled. */
  async followStates(userIds: readonly string[]): Promise<Record<string, FollowState>> {
    const entries = await Promise.all(
      userIds.map(async (userId) => {
        try {
          const response = await accountApi.isFollowing(userId);
          return [userId, response.isFollowing] as const;
        } catch {
          return [userId, null] as const;
        }
      }),
    );
    return Object.fromEntries(entries);
  },
  follow: (userId: string) => accountApi.follow(userId),
  unfollow: (userId: string) => accountApi.unfollow(userId),
};

export const safetyApi = {
  async list(endpoint: string): Promise<User[]> {
    return usersFrom(await api.get<UsersResponse>(`${endpoint}?limit=50&offset=0`));
  },
  remove: (restricted: boolean, userId: string) =>
    restricted
      ? api.patch(`/users/me/restricted/${encodeURIComponent(userId)}/remove`)
      : accountApi.unblock(userId),
};

export const closeFriendsApi = {
  async selected(): Promise<User[]> {
    return usersFrom(await api.get<UsersResponse>('/users/me/close-friends?limit=50&offset=0'));
  },
  async candidates(query: string): Promise<User[]> {
    return usersFrom(
      await api.get<UsersResponse>(
        `/users/me/close-friends/candidates?q=${encodeURIComponent(query)}&limit=50&offset=0`,
      ),
    );
  },
  add: (userId: string) => api.post(`/users/me/close-friends/${encodeURIComponent(userId)}`),
  remove: (userId: string) =>
    api.patch(`/users/me/close-friends/${encodeURIComponent(userId)}/remove`),
};
