import { api } from '../../core/api';
import type { ChatMessage, Conversation, CursorPage, MediaKind, Transcript } from './model';

const root = '/chat';
export const chatRepository = {
  searchUsers: (q: string, offset = 0, signal?: AbortSignal) =>
    api.get<{
      users: Array<{ id: string; displayName: string; avatarUrl: string | null }>;
      hasMore: boolean;
      nextOffset: number | null;
    }>(`/users/search?${new URLSearchParams({ q, offset: String(offset), limit: '20' })}`, {
      signal,
    }),
  blockedUsers: (signal?: AbortSignal) =>
    api.get<{ users: Array<{ id: string }> }>('/users/blocked?limit=20&offset=0', { signal }),
  suggestions: (signal?: AbortSignal) =>
    api.get<{ users: Array<{ id: string; displayName: string; avatarUrl: string | null }> }>(
      '/users/suggestions?limit=10',
      { signal },
    ),
  following: (userId: string, signal?: AbortSignal) =>
    api.get<{ users: Array<{ id: string; displayName: string; avatarUrl: string | null }> }>(
      `/users/${encodeURIComponent(userId)}/following?limit=20&offset=0`,
      { signal },
    ),
  myProducts: async () => {
    const result = await api.get<{
      products: Array<{ id: string; title: string; price: number; images: Array<{ url: string }> }>;
    }>('/products/mine/all');
    return {
      products: result.products.map(({ id, title, price, images }) => ({
        id,
        title,
        price,
        imageUrl: images[0]?.url ?? null,
      })),
    };
  },
  conversations: (
    input: { q?: string; cursor?: string; archived?: boolean; signal?: AbortSignal } = {},
  ) => {
    const query = new URLSearchParams({ limit: '50' });
    if (input.q) query.set('q', input.q);
    if (input.cursor) query.set('cursor', input.cursor);
    return api.get<CursorPage<Conversation>>(
      `${root}/${input.archived ? 'archived' : 'conversations'}?${query}`,
      { signal: input.signal },
    );
  },
  start: (targetUserId: string, productId?: string) =>
    api.post<{ conversationId: string; status: string }>(`${root}/conversations`, {
      targetUserId,
      ...(productId ? { productId } : {}),
    }),
  transcript: (id: string, cursor?: string, signal?: AbortSignal) => {
    const query = new URLSearchParams({ limit: '50' });
    if (cursor) query.set('cursor', cursor);
    return api.get<Transcript>(`${root}/conversations/${encodeURIComponent(id)}?${query}`, {
      signal,
    });
  },
  send: (
    id: string,
    payload: {
      content?: string;
      type?: string;
      attachmentUrl?: string;
      clientMessageId: string;
      replyToId?: string;
      metadata?: Record<string, unknown>;
      viewOnce?: boolean;
      durationMs?: number;
    },
  ) =>
    api.post<ChatMessage>(`${root}/conversations/${encodeURIComponent(id)}/messages`, payload, {
      retryAfterRefresh: false,
    }),
  markRead: (id: string, messageId?: string) =>
    api.patch<void>(
      `${root}/conversations/${encodeURIComponent(id)}/read`,
      messageId ? { messageId } : {},
      { retryAfterRefresh: false },
    ),
  openViewOnce: (conversationId: string, messageId: string, openingKey: string) =>
    api.post<{ messageId: string; readAt: string; mediaUrl: string }>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(messageId)}/view-once/open`,
      { openingKey },
      { retryAfterRefresh: false },
    ),
  closeViewOnce: (conversationId: string, messageId: string, openingKey: string) =>
    api.post<void>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(messageId)}/view-once/close`,
      { openingKey },
      { retryAfterRefresh: false },
    ),
  accept: (id: string) =>
    api.post<void>(`${root}/conversations/${encodeURIComponent(id)}/accept`, undefined, {
      retryAfterRefresh: false,
    }),
  archive: (id: string, archived: boolean) =>
    api.patch<void>(
      `${root}/conversations/${encodeURIComponent(id)}/archive`,
      { archived },
      { retryAfterRefresh: false },
    ),
  deleteConversation: (id: string) =>
    api.patch<void>(`${root}/conversations/${encodeURIComponent(id)}/delete`, undefined, {
      retryAfterRefresh: false,
    }),
  deleteMessage: (conversationId: string, messageId: string) =>
    api.patch<void>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(messageId)}/delete`,
      undefined,
      { retryAfterRefresh: false },
    ),
  react: (conversationId: string, messageId: string, emoji: string) =>
    api.post<{ reactions: NonNullable<ChatMessage['reactions']> }>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(messageId)}/react`,
      { emoji },
      { retryAfterRefresh: false },
    ),
  star: (conversationId: string, messageId: string) =>
    api.post<{ starred: boolean }>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(messageId)}/star`,
      undefined,
      { retryAfterRefresh: false },
    ),
  starred: (conversationId: string) =>
    api.get<ChatMessage[]>(`${root}/conversations/${encodeURIComponent(conversationId)}/starred`),
  forward: (sourceConversationId: string, messageIds: string[], targetConversationIds: string[]) =>
    api.post<{ forwardedCount: number; messages: ChatMessage[] }>(
      `${root}/messages/forward`,
      { sourceConversationId, messageIds, targetConversationIds },
      { retryAfterRefresh: false },
    ),
  media: (conversationId: string, type: MediaKind, cursor?: string, signal?: AbortSignal) => {
    const query = new URLSearchParams({ type, limit: '50' });
    if (cursor) query.set('cursor', cursor);
    return api.get<{ messages: ChatMessage[]; nextCursor: string | null }>(
      `${root}/conversations/${encodeURIComponent(conversationId)}/messages?${query}`,
      { signal },
    );
  },
  theme: (conversationId: string, theme: string) =>
    api.patch(
      `${root}/conversations/${encodeURIComponent(conversationId)}/theme`,
      { theme },
      { retryAfterRefresh: false },
    ),
  mute: (conversationId: string, muted: boolean) =>
    api.patch(
      `${root}/conversations/${encodeURIComponent(conversationId)}/theme`,
      { muted },
      { retryAfterRefresh: false },
    ),
  background: (conversationId: string, backgroundUrl: string) =>
    api.patch(
      `${root}/conversations/${encodeURIComponent(conversationId)}/background`,
      { backgroundUrl },
      { retryAfterRefresh: false },
    ),
  verifyUrl: (url: string) =>
    api.post<{
      url: string;
      normalizedUrl: string;
      host: string;
      isSafe: boolean;
      riskLevel: 'SAFE' | 'SUSPICIOUS' | 'DANGEROUS';
      riskReasons: string[];
      destinationDomain: string;
    }>(`${root}/security/verify-url`, { url }),
  blockUser: (userId: string) => api.post<void>(`/users/${encodeURIComponent(userId)}/block`),
  unblockUser: (userId: string) => api.patch<void>(`/users/${encodeURIComponent(userId)}/unblock`),
  reportUser: (userId: string) =>
    api.post<void>('/reports', { targetType: 'USER', targetId: userId, reason: 'SPAM' }),
  upload: async (file: File, context: 'chat' | 'background' = 'chat', signal?: AbortSignal) => {
    const form = new FormData();
    form.append('file', file);
    return api.post<{ url: string }>(`/uploads?context=${context}`, form, { signal });
  },
};
