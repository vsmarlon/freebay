import { useCallback } from 'react';
import { useMutation, useQuery, useQueryClient, type QueryKey } from '@tanstack/react-query';
import { api } from './api';

type ApiQueryOptions = { auth?: boolean; enabled?: boolean; staleTime?: number };

// ponytail: one query primitive; add a named hook only when two screens share the same endpoint.
export function useApiQuery<T>(key: QueryKey, path: string, options: ApiQueryOptions = {}) {
  const { auth, enabled = true, staleTime } = options;
  const queryFn = useCallback(
    ({ signal }: { signal: AbortSignal }) => api.get<T>(path, { signal, auth }),
    [path, auth],
  );
  return useQuery({ queryKey: key, queryFn, enabled, staleTime });
}

type ApiMutationOptions<TVars, TData> = {
  method?: 'POST' | 'PATCH' | 'DELETE';
  path: string | ((vars: TVars) => string);
  body?: (vars: TVars) => unknown;
  auth?: boolean;
  invalidate?: QueryKey[] | ((data: TData, vars: TVars) => QueryKey[]);
  onSuccess?: (data: TData, vars: TVars) => void;
};

export function useApiMutation<TVars = void, TData = void>(
  options: ApiMutationOptions<TVars, TData>,
) {
  const client = useQueryClient();
  const { method = 'POST', path, body, auth, invalidate, onSuccess } = options;
  const mutationFn = useCallback(
    async (vars: TVars) => {
      const url = typeof path === 'function' ? path(vars) : path;
      const payload = body ? body(vars) : undefined;
      if (method === 'DELETE') return api.delete<TData>(url, { auth });
      return method === 'PATCH'
        ? api.patch<TData>(url, payload, { auth })
        : api.post<TData>(url, payload, { auth });
    },
    [method, path, body, auth],
  );
  return useMutation<TData, unknown, TVars>({
    mutationFn,
    onSuccess: async (data, vars) => {
      onSuccess?.(data, vars);
      if (!invalidate) return;
      const keys = typeof invalidate === 'function' ? invalidate(data, vars) : invalidate;
      await Promise.all(keys.map((queryKey) => client.invalidateQueries({ queryKey })));
    },
  });
}
