import { api } from '../../../core/api';

export type Notice = {
  id: string;
  title?: string;
  body?: string;
  content?: string;
  read: boolean;
  createdAt: string;
  data?: unknown;
  type?: string;
};

export type NotificationsPage = {
  items: Notice[];
  nextCursor: string | null;
  hasMore: boolean;
};

type NotificationsResponse =
  | { items?: Notice[]; data?: Notice[]; nextCursor?: string | null; hasMore?: boolean }
  | Notice[];

const PAGE_SIZE = 20;

export const notificationsApi = {
  async list(cursor: string | undefined, signal?: AbortSignal): Promise<NotificationsPage> {
    const query = new URLSearchParams({
      limit: String(PAGE_SIZE),
      ...(cursor ? { cursor } : {}),
    });
    const result = await api.get<NotificationsResponse>(`/notifications?${query}`, { signal });
    if (Array.isArray(result)) return { items: result, nextCursor: null, hasMore: false };
    const items = result.items ?? result.data ?? [];
    return {
      items,
      nextCursor: result.nextCursor ?? null,
      hasMore: result.hasMore ?? Boolean(result.nextCursor),
    };
  },
  async unreadCount(signal?: AbortSignal): Promise<number> {
    const result = await api.get<{ count: number }>('/notifications/unread-count', { signal });
    if (!Number.isInteger(result.count) || result.count < 0) {
      throw new Error('Invalid unread count');
    }
    return result.count;
  },
  read: (id: string) => api.patch(`/notifications/${encodeURIComponent(id)}/read`),
  readAll: () => api.post('/notifications/read-all'),
};
