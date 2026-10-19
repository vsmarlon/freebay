import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { userKey } from '../../core/query-client';
import { socialApi, searchPage } from './data';
import type { ContentFilter, FeedType, ProfileTimelineKind, TimelineKind } from './types';

export function socialKeys(userId: string) {
  return { root: userKey(userId, 'social'), feed: userKey(userId, 'social', 'feed'), saved: userKey(userId, 'social', 'saved'), liked: userKey(userId, 'social', 'liked'), timeline: (id: string) => userKey(userId, 'social', 'timeline', id), post: (id: string) => userKey(userId, 'social', 'post', id), comments: (id: string) => userKey(userId, 'social', 'comments', id) };
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
  return useInfiniteQuery({ queryKey: socialKeys(userId).timeline(`${ownerId}:${kind}`), initialPageParam: undefined as string | undefined, queryFn: ({ pageParam, signal }) => socialApi.timeline(ownerId, protocolKind, pageParam, signal, Boolean(userId)), getNextPageParam: (page) => page.hasMore ? page.nextCursor : null, enabled: Boolean(ownerId), staleTime: 0, gcTime: 0, refetchOnMount: 'always' });
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

export function useSocialActions(userId: string) {
  const client = useQueryClient();
  const keys = socialKeys(userId);
  const refresh = async (postId?: string) => {
    await Promise.all([client.invalidateQueries({ queryKey: keys.root }), ...(postId ? [client.invalidateQueries({ queryKey: keys.post(postId) }), client.invalidateQueries({ queryKey: keys.comments(postId) })] : [])]);
  };
  const useAction = (run: (id: string) => Promise<unknown>) => useMutation({ mutationFn: run, onSuccess: (_, id) => refresh(id) });
  return {
    like: useAction((id) => socialApi.likePost(id, false)), unlike: useAction((id) => socialApi.likePost(id, true)),
    repost: useAction((id) => socialApi.repost(id, false)), unshare: useAction((id) => socialApi.repost(id, true)),
    save: useAction((id) => socialApi.save(id, false)), unsave: useAction((id) => socialApi.save(id, true)),
    deletePost: useAction((id) => socialApi.deletePost(id)), createPost: useMutation({ mutationFn: socialApi.createPost, onSuccess: () => refresh() }),
    createComment: useMutation({ mutationFn: ({ id, content, parentId }: { id: string; content: string; parentId?: string }) => socialApi.createComment(id, content, parentId), onSuccess: (_, vars) => refresh(vars.id) }),
    deleteComment: useMutation({ mutationFn: (input: { id: string; postId: string }) => socialApi.deleteComment(input.id), onSuccess: (_, vars) => refresh(vars.postId) }), report: useMutation({ mutationFn: ({ type, id, reason, description }: { type: 'POST' | 'USER'; id: string; reason: import('./types').ReportReason; description?: string }) => socialApi.report(type, id, reason, description) }),
    approveComment: useMutation({ mutationFn: (input: { id: string; postId: string }) => socialApi.approveComment(input.id), onSuccess: (_, vars) => refresh(vars.postId) }),
  };
}
