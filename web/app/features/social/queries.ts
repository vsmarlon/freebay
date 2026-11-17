import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
  type InfiniteData,
  type QueryClient,
} from '@tanstack/react-query';
import { userKey } from '../../core/query-client';
import { commentList, socialApi, searchPage } from './data';
import type {
  Comment,
  CommentsPage,
  CommentViewPatch,
  ContentFilter,
  CursorPage,
  FeedPage,
  FeedType,
  MutationState,
  Post,
  PostViewPatch,
  ProfileTimelineKind,
  SaveMutationState,
  TimelineEntry,
  TimelineKind,
} from './types';

export function socialKeys(userId: string) {
  return {
    root: userKey(userId, 'social'),
    feed: userKey(userId, 'social', 'feed'),
    saved: userKey(userId, 'social', 'saved'),
    liked: userKey(userId, 'social', 'liked'),
    search: userKey(userId, 'social', 'search'),
    /** Prefix over every profile timeline of this viewer. */
    timelines: userKey(userId, 'social', 'timeline'),
    /** Prefix over every post's comment pages of this viewer. */
    commentPages: userKey(userId, 'social', 'comments'),
    timeline: (id: string) => userKey(userId, 'social', 'timeline', id),
    post: (id: string) => userKey(userId, 'social', 'post', id),
    comments: (id: string) => userKey(userId, 'social', 'comments', id),
  };
}

export const patchPostView = (post: Post, postId: string, patch: PostViewPatch): Post =>
  post.id === postId ? { ...post, ...patch } : post;

export function patchPostList(posts: Post[], postId: string, patch: PostViewPatch): Post[] {
  return posts.map((post) => patchPostView(post, postId, patch));
}

export function patchFeedPage(page: FeedPage, postId: string, patch: PostViewPatch): FeedPage {
  return { ...page, posts: patchPostList(page.posts, postId, patch) };
}

export function patchPostItemPage(
  page: CursorPage<Post>,
  postId: string,
  patch: PostViewPatch,
): CursorPage<Post> {
  return { ...page, items: patchPostList(page.items, postId, patch) };
}

// Timeline entries carry the post plus the owner's repost metadata: only the post is the
// viewer's render state, so `isReposted`/`repostedAt` must survive a reaction patch.
export function patchTimelinePage(
  page: CursorPage<TimelineEntry>,
  postId: string,
  patch: PostViewPatch,
): CursorPage<TimelineEntry> {
  return {
    ...page,
    items: page.items.map((entry) => ({
      ...entry,
      post: patchPostView(entry.post, postId, patch),
    })),
  };
}

export function patchCommentRow(
  comment: Comment,
  commentId: string,
  patch: CommentViewPatch,
): Comment {
  if (comment.id === commentId) return { ...comment, ...patch };
  if (!comment.replies?.length) return comment;
  return {
    ...comment,
    replies: comment.replies.map((reply) => patchCommentRow(reply, commentId, patch)),
  };
}

export function patchCommentsPage(
  page: CommentsPage,
  commentId: string,
  patch: CommentViewPatch,
): CommentsPage {
  return Array.isArray(page)
    ? page.map((comment) => patchCommentRow(comment, commentId, patch))
    : {
        ...page,
        comments: page.comments.map((comment) => patchCommentRow(comment, commentId, patch)),
      };
}

const patchInfinitePages = <TPage>(
  data: InfiniteData<TPage>,
  patchPage: (page: TPage) => TPage,
): InfiniteData<TPage> => ({ ...data, pages: data.pages.map((page) => patchPage(page)) });

// Authoritative write-through: the mutation response ({ active, count }) is the server's
// post-transaction truth, so every cached *view* of this post is patched by its known key
// instead of guessing at whatever shape happens to sit under the social root.
export function patchPostViews(
  client: QueryClient,
  userId: string,
  postId: string,
  patch: PostViewPatch,
) {
  const keys = socialKeys(userId);
  client.setQueriesData<InfiniteData<FeedPage>>({ queryKey: keys.feed }, (data) =>
    data ? patchInfinitePages(data, (page) => patchFeedPage(page, postId, patch)) : data,
  );
  client.setQueriesData<InfiniteData<CursorPage<Post>>>({ queryKey: keys.saved }, (data) =>
    data ? patchInfinitePages(data, (page) => patchPostItemPage(page, postId, patch)) : data,
  );
  client.setQueriesData<InfiniteData<CursorPage<Post>>>({ queryKey: keys.search }, (data) =>
    data ? patchInfinitePages(data, (page) => patchPostItemPage(page, postId, patch)) : data,
  );
  client.setQueriesData<InfiniteData<CursorPage<TimelineEntry>>>(
    { queryKey: keys.timelines },
    (data) =>
      data ? patchInfinitePages(data, (page) => patchTimelinePage(page, postId, patch)) : data,
  );
  client.setQueriesData<Post[]>({ queryKey: keys.liked }, (data) =>
    data ? patchPostList(data, postId, patch) : data,
  );
  const detailKey = keys.post(postId);
  const detail = client.getQueryData<Post>(detailKey);
  if (detail) client.setQueryData<Post>(detailKey, patchPostView(detail, postId, patch));
}

export function patchCommentViews(
  client: QueryClient,
  userId: string,
  commentId: string,
  patch: CommentViewPatch,
) {
  client.setQueriesData<InfiniteData<CommentsPage>>(
    { queryKey: socialKeys(userId).commentPages },
    (data) =>
      data ? patchInfinitePages(data, (page) => patchCommentsPage(page, commentId, patch)) : data,
  );
}

export function useSocialActions(userId: string) {
  const client = useQueryClient();
  const keys = socialKeys(userId);
  const patchViews = (postId: string, patch: PostViewPatch) =>
    patchPostViews(client, userId, postId, patch);
  const patchComments = (commentId: string, patch: CommentViewPatch) =>
    patchCommentViews(client, userId, commentId, patch);
  const invalidateAll = (postId?: string) =>
    Promise.all([
      client.invalidateQueries({ queryKey: keys.root }),
      ...(postId
        ? [
            client.invalidateQueries({ queryKey: keys.post(postId) }),
            client.invalidateQueries({ queryKey: keys.comments(postId) }),
          ]
        : []),
    ]);

  // One toggle mutation per reaction; the caller supplies `active` from the
  // post's own flag instead of six hook instances differing only by `active`.
  type ReactionToggle = { id: string; active: boolean };
  const useReaction = <S extends MutationState | SaveMutationState>(
    reaction: (input: ReactionToggle) => Promise<S>,
    patchOf: (state: S) => PostViewPatch,
  ) =>
    useMutation({
      mutationFn: reaction,
      onSuccess: (state, input) => patchViews(input.id, patchOf(state)),
    });

  return {
    like: useReaction(
      ({ id, active }) => socialApi.likePost(id, active),
      (state) => ({ isLiked: state.active, likesCount: state.count }),
    ),
    repost: useReaction(
      ({ id, active }) => socialApi.repost(id, active),
      (state) => ({ hasReposted: state.active, sharesCount: state.count }),
    ),
    save: useReaction(
      ({ id, active }) => socialApi.save(id, active),
      (state) => ({ isSaved: state.active }),
    ),
    deletePost: useMutation({
      mutationFn: (id: string) => socialApi.deletePost(id),
      onSuccess: (_, id) => invalidateAll(id),
    }),
    createPost: useMutation({
      mutationFn: socialApi.createPost,
      onSuccess: () => client.invalidateQueries({ queryKey: keys.root }),
    }),
    createComment: useMutation({
      mutationFn: ({ id, content, parentId }: { id: string; content: string; parentId?: string }) =>
        socialApi.createComment(id, content, parentId),
      onSuccess: (created, vars) => {
        patchViews(vars.id, { commentsCount: created.commentsCount });
        void client.invalidateQueries({ queryKey: keys.comments(vars.id) });
      },
    }),
    deleteComment: useMutation({
      mutationFn: (input: { id: string; postId: string }) => socialApi.deleteComment(input.id),
      onSuccess: (_, vars) => invalidateAll(vars.postId),
    }),
    approveComment: useMutation({
      mutationFn: (input: { id: string; postId: string }) => socialApi.approveComment(input.id),
      onSuccess: (_, vars) => invalidateAll(vars.postId),
    }),
    report: useMutation({
      mutationFn: ({
        type,
        id,
        reason,
        description,
      }: {
        type: 'POST' | 'USER';
        id: string;
        reason: import('./types').ReportReason;
        description?: string;
      }) => socialApi.report(type, id, reason, description),
    }),
    patchViews,
    patchComments,
  };
}

export function useFeed(userId: string, type: FeedType, contentFilter: ContentFilter) {
  return useInfiniteQuery({
    queryKey: [...socialKeys(userId).feed, type, contentFilter],
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) => socialApi.feed(type, contentFilter, pageParam, signal),
    getNextPageParam: (page) => (page.hasMore ? (page.nextCursor ?? undefined) : undefined),
    enabled: Boolean(userId),
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
  });
}

export function useSavedPosts(userId: string) {
  return useInfiniteQuery({
    queryKey: socialKeys(userId).saved,
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) => socialApi.saved(pageParam, signal),
    getNextPageParam: (page) => (page.hasMore ? (page.nextCursor ?? undefined) : undefined),
    enabled: Boolean(userId),
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
  });
}

export function useLikedPosts(userId: string) {
  return useQuery({
    queryKey: socialKeys(userId).liked,
    queryFn: ({ signal }) => socialApi.liked(signal),
    enabled: Boolean(userId),
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
  });
}

export function useTimeline(userId: string, ownerId: string, kind: TimelineKind = 'all') {
  const protocolKind: ProfileTimelineKind | undefined =
    kind === 'all'
      ? undefined
      : kind === 'post'
        ? 'posts'
        : kind === 'repost'
          ? 'reposts'
          : 'products';
  return useInfiniteQuery({
    queryKey: socialKeys(userId).timeline(`${ownerId}:${kind}`),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) =>
      socialApi.timeline(ownerId, protocolKind, pageParam, signal, Boolean(userId)),
    getNextPageParam: (page) => (page.hasMore ? (page.nextCursor ?? undefined) : undefined),
    enabled: Boolean(ownerId),
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
  });
}

export function useMyPosts(userId: string) {
  return useInfiniteQuery({
    queryKey: socialKeys(userId).timeline('mine'),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) => socialApi.userPosts(userId, pageParam, signal),
    getNextPageParam: (page) => (page.hasMore ? (page.nextCursor ?? undefined) : undefined),
    enabled: Boolean(userId),
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
  });
}

export function usePost(userId: string, postId: string) {
  return useQuery({
    queryKey: socialKeys(userId).post(postId),
    queryFn: ({ signal }) => socialApi.post(postId, signal),
    enabled: Boolean(postId),
    staleTime: 0,
    gcTime: 0,
  });
}

export function useComments(userId: string, postId: string) {
  return useInfiniteQuery({
    queryKey: socialKeys(userId).comments(postId),
    initialPageParam: 0,
    queryFn: ({ pageParam, signal }) => socialApi.comments(postId, pageParam, signal),
    getNextPageParam: (page, pages) => {
      if (commentList(page).length !== 20) return undefined;
      return pages.reduce((count, prior) => count + commentList(prior).length, 0);
    },
    enabled: Boolean(postId),
    staleTime: 0,
    gcTime: 0,
  });
}

export function usePostSearch(
  userId: string,
  query: string,
  filter: 'all' | 'following' | 'followers',
) {
  return useInfiniteQuery({
    queryKey: [...socialKeys(userId).search, query.trim(), filter],
    initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) =>
      searchPage(await socialApi.search(query.trim(), filter, pageParam, signal)),
    getNextPageParam: (page) => (page.hasMore ? (page.nextCursor ?? undefined) : undefined),
    enabled: Boolean(query.trim()),
    staleTime: 0,
    gcTime: 0,
  });
}
