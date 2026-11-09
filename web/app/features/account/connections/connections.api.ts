import { api } from '../../../core/api';
import type { User } from '../account';

export const PAGE_SIZE = 20;
type ConnectionsResponse = { users?: User[]; items?: User[] } | User[];
export type FollowState = boolean | null;

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
          const response = await api.get<{ isFollowing: boolean }>(
            `/users/${encodeURIComponent(userId)}/is-following`,
          );
          return [userId, response.isFollowing] as const;
        } catch {
          return [userId, null] as const;
        }
      }),
    );
    return Object.fromEntries(entries);
  },
  follow: (userId: string) => api.post(`/users/${encodeURIComponent(userId)}/follow`),
  unfollow: (userId: string) => api.patch(`/users/${encodeURIComponent(userId)}/unfollow`),
};
