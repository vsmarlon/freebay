import { api } from '../../../core/api';
import { usersFrom, type UsersResponse } from '../api';
import type { User } from '../account';

export const safetyApi = {
  async list(endpoint: string): Promise<User[]> {
    return usersFrom(await api.get<UsersResponse>(`${endpoint}?limit=50&offset=0`));
  },
  remove: (restricted: boolean, userId: string) =>
    restricted
      ? api.patch(`/users/me/restricted/${encodeURIComponent(userId)}/remove`)
      : api.patch(`/users/${encodeURIComponent(userId)}/unblock`),
};
