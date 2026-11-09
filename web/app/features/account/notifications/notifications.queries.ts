import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
  type InfiniteData,
} from '@tanstack/react-query';
import { notificationsApi, type Notice, type NotificationsPage } from './notifications.api';

export const notificationsKeys = {
  list: (userId: string | undefined) => ['account', 'notifications', userId ?? ''] as const,
  unread: (userId: string | undefined) =>
    ['account', 'notifications', userId ?? '', 'unread'] as const,
};

export function useNotifications(userId: string | undefined) {
  return useInfiniteQuery({
    queryKey: notificationsKeys.list(userId),
    enabled: Boolean(userId),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) => notificationsApi.list(pageParam, signal),
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    retry: false,
  });
}

export function useUnreadCount(userId: string | undefined) {
  return useQuery({
    queryKey: notificationsKeys.unread(userId),
    enabled: Boolean(userId),
    queryFn: ({ signal }) => notificationsApi.unreadCount(signal),
    retry: false,
  });
}

function patchRead(
  client: ReturnType<typeof useQueryClient>,
  userId: string | undefined,
  matches: (notice: Notice) => boolean,
) {
  client.setQueryData<InfiniteData<NotificationsPage>>(notificationsKeys.list(userId), (data) =>
    data
      ? {
          ...data,
          pages: data.pages.map((page) => ({
            ...page,
            items: page.items.map((notice) =>
              matches(notice) ? { ...notice, read: true } : notice,
            ),
          })),
        }
      : data,
  );
}

export function useReadNotification(userId: string | undefined) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => notificationsApi.read(id),
    onSuccess: (_data, id) => {
      patchRead(client, userId, (notice) => notice.id === id);
      void client.invalidateQueries({ queryKey: notificationsKeys.unread(userId) });
    },
  });
}

export function useReadAllNotifications(userId: string | undefined) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: () => notificationsApi.readAll(),
    onSuccess: () => {
      patchRead(client, userId, () => true);
      void client.invalidateQueries({ queryKey: notificationsKeys.unread(userId) });
    },
  });
}
