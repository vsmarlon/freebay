import { api } from '../../core/api';
import type { Comment, ContentFilter, CursorPage, FeedPage, FeedType, Post, PostAudience, PostType, ProfileTimelineKind, ReportReason, ReportTargetType, TimelineEntry } from './types';

const params = (values: Record<string, string | number | undefined>) => {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(values)) if (value !== undefined && value !== '') search.set(key, String(value));
  return search.size ? `?${search}` : '';
};

export const socialApi = {
  feed: (type: FeedType, contentFilter: ContentFilter, cursor?: string, signal?: AbortSignal) => api.get<FeedPage>(`/social/feed${params({ type, contentFilter, cursor, limit: 20 })}`, { signal }),
  post: (id: string, signal?: AbortSignal) => api.get<Post>(`/social/posts/${encodeURIComponent(id)}`, { signal }),
  comments: (id: string, offset = 0, signal?: AbortSignal) => api.get<Comment[] | { comments: Comment[] }>(`/social/posts/${encodeURIComponent(id)}/comments${params({ limit: 20, offset })}`, { signal }),
  saved: (cursor?: string, signal?: AbortSignal) => api.get<FeedPage>(`/social/posts/saved${params({ limit: 20, cursor })}`, { signal }),
  liked: (signal?: AbortSignal) => api.get<Post[]>('/social/posts/liked', { signal }),
  timeline: (userId: string, kind: ProfileTimelineKind | undefined, cursor?: string, signal?: AbortSignal, authenticated = true) => api.get<CursorPage<TimelineEntry>>(`/social/posts/user/${encodeURIComponent(userId)}/timeline${params({ kind, limit: 20, cursor })}`, { signal, auth: authenticated }),
  userPosts: (userId: string, cursor?: string, signal?: AbortSignal) => api.get<CursorPage<TimelineEntry>>(`/social/posts/user/${encodeURIComponent(userId)}${params({ limit: 20, cursor })}`, { signal }),
  search: (query: string, filter: 'all' | 'following' | 'followers', cursor?: string, signal?: AbortSignal) => api.get<Post[]>(`/social/posts/search${params({ q: query, filter, limit: 20, cursor })}`, { signal }),
  createPost: (input: { content: string; type: PostType; audience: PostAudience; image?: File; mentionIds?: string[] }) => {
    const body = new FormData();
    body.set('content', input.content);
    body.set('type', input.type);
    body.set('audience', input.audience);
    if (input.image) body.set('image', input.image);
    for (const id of input.mentionIds ?? []) body.append('mentionIds', id);
    return api.post<Post>('/social/posts', body);
  },
  deletePost: (id: string) => api.patch<void>(`/social/posts/${encodeURIComponent(id)}/delete`),
  likePost: (id: string, active: boolean) => active ? api.patch<void>(`/social/posts/${encodeURIComponent(id)}/unlike`) : api.post<void>(`/social/posts/${encodeURIComponent(id)}/like`),
  repost: (id: string, active: boolean) => active ? api.patch<void>(`/social/posts/${encodeURIComponent(id)}/unshare`) : api.post<void>(`/social/posts/${encodeURIComponent(id)}/share`),
  save: (id: string, active: boolean) => active ? api.patch<void>(`/social/posts/${encodeURIComponent(id)}/unsave`) : api.post<void>(`/social/posts/${encodeURIComponent(id)}/save`),
  createComment: (id: string, content: string, parentId?: string, mentionIds?: string[]) => api.post<Comment>(`/social/posts/${encodeURIComponent(id)}/comments`, { content, parentId, mentionIds }),
  deleteComment: (id: string) => api.patch<void>(`/social/comments/${encodeURIComponent(id)}/delete`),
  approveComment: (id: string) => api.patch<void>(`/social/comments/${encodeURIComponent(id)}/approve`),
  likeComment: (id: string, active: boolean) => active ? api.patch<void>(`/social/comments/${encodeURIComponent(id)}/unlike`) : api.post<void>(`/social/comments/${encodeURIComponent(id)}/like`),
  report: (targetType: ReportTargetType, targetId: string, reason: ReportReason, description?: string) => api.post<void>('/reports', { targetType, targetId, reason, description }),
};

// Search returns a flat array, not CursorPage; the API accepts an id cursor but exposes no hasMore.
export function searchPage(posts: Post[]): CursorPage<Post> {
  const hasMore = posts.length === 20;
  return { items: posts, hasMore, nextCursor: hasMore ? posts.at(-1)?.id ?? null : null };
}

export function commentList(response: Comment[] | { comments: Comment[] }): Comment[] {
  return Array.isArray(response) ? response : response.comments;
}
