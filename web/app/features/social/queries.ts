import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { userKey } from '../../core/query-client';
import { socialApi, searchPage } from './data';
import type { Comment, ContentFilter, FeedType, MutationState, Post, ProfileTimelineKind, SaveMutationState, TimelineEntry, TimelineKind } from './types';

export function socialKeys(userId: string) {
  return { root: userKey(userId, 'social'), feed: userKey(userId, 'social', 'feed'), saved: userKey(userId, 'social', 'saved'), liked: userKey(userId, 'social', 'liked'), timeline: (id: string) => userKey(userId, 'social', 'timeline', id), post: (id: string) => userKey(userId, 'social', 'post', id), comments: (id: string) => userKey(userId, 'social', 'comments', id) };
}

const isPostView = (value: unknown): value is Post =>
  typeof value === 'object' && value !== null && 'audience' in value && 'isLiked' in value;
const isTimelineEntryView = (value: unknown): value is TimelineEntry =>
  typeof value === 'object' && value !== null && 'post' in value && 'isReposted' in value;
const isCommentView = (value: unknown): value is Comment =>
  typeof value === 'object' && value !== null && 'content' in value && 'likesCount' in value && 'isHidden' in value && !('audience' in value);

type PostViewPatch = Partial<Pick<Post, 'isLiked' | 'likesCount' | 'isSaved' | 'hasReposted' | 'sharesCount' | 'commentsCount'>>;
type CommentViewPatch = Partial<Pick<Comment, 'isLiked' | 'likesCount'>>;

export function patchPostInRecord(record: unknown, postId: string, patch: PostViewPatch): unknown {
  if (Array.isArray(record)) return record.map((item: unknown) => patchPostInRecord(item, postId, patch));
  if (typeof record !== 'object' || record === null) return record;
  if ('pages' in record && Array.isArray(record.pages)) {
    return { ...record, pages: record.pages.map((page: unknown) => patchPostInRecord(page, postId, patch)) };
  }
  if ('posts' in record && Array.isArray(record.posts)) {
    return { ...record, posts: record.posts.map((item: unknown) => (isPostView(item) && item.id === postId ? { ...item, ...patch } : item)) };
  }
  if ('items' in record && Array.isArray(record.items)) {
    return { ...record, items: record.items.map((item: unknown) => (isTimelineEntryView(item) && item.post.id === postId ? { ...item, post: { ...item.post, ...patch } } : isPostView(item) && item.id === postId ? { ...item, ...patch } : item)) };
  }
  if (isPostView(record) && record.id === postId) return { ...record, ...patch };
  return record;
}

export function patchCommentInPages(data: unknown, commentId: string, patch: CommentViewPatch): unknown {
  const patchRow = (row: unknown): unknown => {
    if (!isCommentView(row)) return row;
    if (row.id === commentId) return { ...row, ...patch };
    return row.replies?.length ? { ...row, replies: row.replies.map(patchRow) } : row;
  };
  if (Array.isArray(data)) return data.map(patchRow);
  if (typeof data === 'object' && data !== null && 'pages' in data && Array.isArray(data.pages)) {
    return { ...data, pages: data.pages.map((page: unknown) => patchCommentInPages(page, commentId, patch)) };
  }
  if (typeof data === 'object' && data !== null && 'comments' in data && Array.isArray(data.comments)) {
    return { ...data, comments: data.comments.map(patchRow) };
  }
  return data;
}

export function useSocialActions(userId: string) {
  const client = useQueryClient();
  const keys = socialKeys(userId);
  // Authoritative write-through: the mutation response ({ active, count }) is the
  // server's post-transaction truth; patch every cached social view of the post.
  const patchViews = (postId: string, patch: PostViewPatch) => {
    client.setQueriesData({ queryKey: keys.root }, (data: unknown) => patchPostInRecord(data, postId, patch));
  };
  const patchComments = (commentId: string, patch: CommentViewPatch) => {
    client.setQueriesData({ queryKey: keys.root }, (data: unknown) => patchCommentInPages(data, commentId, patch));
  };
  const invalidateAll = (postId?: string) =>
    Promise.all([client.invalidateQueries({ queryKey: keys.root }), ...(postId ? [client.invalidateQueries({ queryKey: keys.post(postId) }), client.invalidateQueries({ queryKey: keys.comments(postId) })] : [])]);

  // One toggle mutation per reaction; the caller supplies `active` from the
  // post's own flag instead of six hook instances differing only by `active`.
  type ReactionToggle = { id: string; active: boolean };
  const useReaction = <S extends MutationState | SaveMutationState>(
    reaction: (input: ReactionToggle) => Promise<S>,
    patchOf: (state: S) => PostViewPatch,
  ) =>
    useMutation({ mutationFn: reaction, onSuccess: (state, input) => patchViews(input.id, patchOf(state)) });

  return {
    like: useReaction(({ id, active }) => socialApi.likePost(id, active), (state) => ({ isLiked: state.active, likesCount: state.count })),
    repost: useReaction(({ id, active }) => socialApi.repost(id, active), (state) => ({ hasReposted: state.active, sharesCount: state.count })),
    save: useReaction(({ id, active }) => socialApi.save(id, active), (state) => ({ isSaved: state.active })),
    deletePost: useMutation({ mutationFn: (id: string) => socialApi.deletePost(id), onSuccess: (_, id) => invalidateAll(id) }),
    createPost: useMutation({ mutationFn: socialApi.createPost, onSuccess: () => client.invalidateQueries({ queryKey: keys.root }) }),
    createComment: useMutation({
      mutationFn: ({ id, content, parentId }: { id: string; content: string; parentId?: string }) => socialApi.createComment(id, content, parentId),
      onSuccess: (created, vars) => {
        patchViews(vars.id, { commentsCount: created.commentsCount });
        void client.invalidateQueries({ queryKey: keys.comments(vars.id) });
      },
    }),
    deleteComment: useMutation({ mutationFn: (input: { id: string; postId: string }) => socialApi.deleteComment(input.id), onSuccess: (_, vars) => invalidateAll(vars.postId) }),
    approveComment: useMutation({ mutationFn: (input: { id: string; postId: string }) => socialApi.approveComment(input.id), onSuccess: (_, vars) => invalidateAll(vars.postId) }),
    report: useMutation({ mutationFn: ({ type, id, reason, description }: { type: 'POST' | 'USER'; id: string; reason: import('./types').ReportReason; description?: string }) => socialApi.report(type, id, reason, description) }),
    patchViews, patchComments,
  };
}

export function useFeed(userId: string, type: FeedType, contentFilter: ContentFilter) {
  return useInfiniteQuery({ queryKey: [...socialKeys(userId).feed, type, contentFilter], initialPageParam: undefined as string | undefined, queryFn: ({ pageParam, signal }) => socialApi.feed(type, contentFilter, pageParam, signal), getNextPageParam: (page) => page.hasMore ? page.nextCursor ?? undefined : undefined, enabled: Boolean(userId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
}

export function useSavedPosts(userId: string) {
  return useInfiniteQuery({ queryKey: socialKeys(userId).saved, initialPageParam: undefined as string | undefined, queryFn: ({ pageParam, signal }) => socialApi.saved(pageParam, signal), getNextPageParam: (page) => page.hasMore ? page.nextCursor ?? undefined : undefined, enabled: Boolean(userId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
}

export function useLikedPosts(userId: string) {
  return useQuery({ queryKey: socialKeys(userId).liked, queryFn: ({ signal }) => socialApi.liked(signal), enabled: Boolean(userId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
}

export function useTimeline(userId: string, ownerId: string, kind: TimelineKind = 'all') {
  const protocolKind: ProfileTimelineKind | undefined = kind === 'all' ? undefined : kind === 'post' ? 'posts' : kind === 'repost' ? 'reposts' : 'products';
  return useInfiniteQuery({ queryKey: socialKeys(userId).timeline(`${ownerId}:${kind}`), initialPageParam: undefined as string | undefined, queryFn: ({ pageParam, signal }) => socialApi.timeline(ownerId, protocolKind, pageParam, signal, Boolean(userId)), getNextPageParam: (page) => page.hasMore ? page.nextCursor ?? undefined : undefined, enabled: Boolean(ownerId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
}

export function useMyPosts(userId: string) {
  return useInfiniteQuery({ queryKey: socialKeys(userId).timeline('mine'), initialPageParam: undefined as string | undefined, queryFn: ({ pageParam, signal }) => socialApi.userPosts(userId, pageParam, signal), getNextPageParam: (page) => page.hasMore ? page.nextCursor ?? undefined : undefined, enabled: Boolean(userId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
}

export function usePost(userId: string, postId: string) {
  return useQuery({ queryKey: socialKeys(userId).post(postId), queryFn: ({ signal }) => socialApi.post(postId, signal), enabled: Boolean(postId), staleTime: 0, gcTime: 0 });
}

export function useComments(userId: string, postId: string) {
  return useInfiniteQuery({ queryKey: socialKeys(userId).comments(postId), initialPageParam: 0, queryFn: ({ pageParam, signal }) => socialApi.comments(postId, pageParam, signal), getNextPageParam: (page, pages) => { const rows = Array.isArray(page) ? page : page.comments; return rows.length === 20 ? pages.reduce((count, prior) => count + (Array.isArray(prior) ? prior.length : prior.comments.length), 0) : undefined; }, enabled: Boolean(postId), staleTime: 0, gcTime: 0 });
}

export function usePostSearch(userId: string, query: string, filter: 'all' | 'following' | 'followers') {
  return useInfiniteQuery({ queryKey: userKey(userId, 'social', 'search', query.trim(), filter), initialPageParam: undefined as string | undefined, queryFn: async ({ pageParam, signal }) => searchPage(await socialApi.search(query.trim(), filter, pageParam, signal)), getNextPageParam: (page) => page.hasMore ? page.nextCursor ?? undefined : undefined, enabled: Boolean(query.trim()), staleTime: 0, gcTime: 0 });
}
