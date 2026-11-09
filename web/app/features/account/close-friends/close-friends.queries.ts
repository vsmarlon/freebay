import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { closeFriendsApi } from './close-friends.api';

export const closeFriendsKeys = {
  all: ['account', 'close-friends'] as const,
  search: (query: string) => ['account', 'close-friends', 'search', query] as const,
};

export function useCloseFriends(query: string) {
  return useQuery({
    queryKey: closeFriendsKeys.search(query),
    queryFn: async () => ({
      selected: await closeFriendsApi.selected(),
      candidates: await closeFriendsApi.candidates(query),
    }),
    retry: false,
  });
}

export function useChangeCloseFriend() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (input: { userId: string; add: boolean }) =>
      input.add ? closeFriendsApi.add(input.userId) : closeFriendsApi.remove(input.userId),
    onSuccess: () => client.invalidateQueries({ queryKey: closeFriendsKeys.all }),
  });
}
