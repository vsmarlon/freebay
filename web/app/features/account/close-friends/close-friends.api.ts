import { api } from '../../../core/api';
import { usersFrom, type UsersResponse } from '../api';
import type { User } from '../account';

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
