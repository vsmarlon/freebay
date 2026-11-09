import { api } from '../../../core/api';
import type { User } from '../account';

type UsersResponse = { users?: User[] } | User[];

const usersOf = (result: UsersResponse): User[] =>
  Array.isArray(result) ? result : (result.users ?? []);

export const safetyApi = {
  async list(endpoint: string): Promise<User[]> {
    return usersOf(await api.get<UsersResponse>(`${endpoint}?limit=50&offset=0`));
  },
  remove: (restricted: boolean, userId: string) =>
    restricted
      ? api.patch(`/users/me/restricted/${encodeURIComponent(userId)}/remove`)
      : api.patch(`/users/${encodeURIComponent(userId)}/unblock`),
};
