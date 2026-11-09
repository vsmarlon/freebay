import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { safetyApi } from './safety.api';

export const safetyKeys = {
  list: (endpoint: string) => ['account', 'safety', endpoint] as const,
};

export function useSafetyList(endpoint: string) {
  return useQuery({
    queryKey: safetyKeys.list(endpoint),
    queryFn: () => safetyApi.list(endpoint),
    retry: false,
  });
}

export function useRemoveSafety(endpoint: string, restricted: boolean) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (userId: string) => safetyApi.remove(restricted, userId),
    onSuccess: () => client.invalidateQueries({ queryKey: safetyKeys.list(endpoint) }),
  });
}
