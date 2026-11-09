import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
  type InfiniteData,
} from '@tanstack/react-query';
import type { User } from '../account';
import { connectionsApi, PAGE_SIZE, type FollowState } from '../api';

export const connectionKeys = {
  list: (endpoint: string) => ['account', 'connections', endpoint] as const,
  followStates: (endpoint: string, ids: readonly string[]) =>
    ['account', 'connections', endpoint, 'follow-states', ids] as const,
  followStatesPrefix: (endpoint: string) =>
    ['account', 'connections', endpoint, 'follow-states'] as const,
};

export function useConnections(endpoint: string) {
  return useInfiniteQuery({
    queryKey: connectionKeys.list(endpoint),
    initialPageParam: 0,
    queryFn: ({ pageParam, signal }) => connectionsApi.list(endpoint, pageParam, signal),
    getNextPageParam: (lastPage, allPages) =>
      lastPage.length < PAGE_SIZE ? undefined : allPages.length * PAGE_SIZE,
    retry: false,
  });
}

export function useFollowStates(endpoint: string, ids: readonly string[], enabled: boolean) {
  return useQuery({
    queryKey: connectionKeys.followStates(endpoint, ids),
    queryFn: () => connectionsApi.followStates(ids),
    enabled: enabled && ids.length > 0,
    staleTime: 30_000,
    retry: false,
  });
}

export function useToggleFollow(endpoint: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (input: { userId: string; following: boolean; removeFromList: boolean }) =>
      input.following ? connectionsApi.unfollow(input.userId) : connectionsApi.follow(input.userId),
    onSuccess: (_data, input) => {
      if (input.removeFromList) {
        client.setQueryData<InfiniteData<User[]>>(connectionKeys.list(endpoint), (data) =>
          data
            ? {
                ...data,
                pages: data.pages.map((page) => page.filter((user) => user.id !== input.userId)),
              }
            : data,
        );
        return;
      }
      client.setQueriesData<Record<string, FollowState>>(
        { queryKey: connectionKeys.followStatesPrefix(endpoint) },
        (states) => (states ? { ...states, [input.userId]: !input.following } : states),
      );
    },
  });
}
