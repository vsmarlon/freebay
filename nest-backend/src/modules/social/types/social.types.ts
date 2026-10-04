import { Prisma } from "@prisma/client";
import { DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';

export enum FeedType {
  EXPLORE = "explore",
  FOLLOWING = "following",
}

export enum ContentFilter {
  ALL = "all",
  SOCIAL = "social",
  SELLING = "selling",
}

export enum SearchFilter {
  ALL = "all",
  FOLLOWING = "following",
  FOLLOWERS = "followers",
}

export const COMMENT_MAX_LENGTH = 1000;
export const SEARCH_MAX_LENGTH = 200;
export const COMMENT_REPLY_MAX_COUNT = 50;
export const EXPLORE_CANDIDATE_WINDOW = 60;
export const SOCIAL_DEFAULT_PAGE_SIZE = DEFAULT_PAGE_SIZE;

export const POST_INCLUDE = {
  user: {
    select: {
      id: true,
      displayName: true,
      username: true,
      avatarUrl: true,
      avatarBlurHash: true,
      isVerified: true,
    },
  },
  likes: { take: 1, select: { userId: true } },
  shares: { take: 1, select: { userId: true } },
  savedBy: { take: 1, select: { userId: true } },
  _count: { select: { likes: true, comments: { where: { deletedAt: null, isHidden: false } }, shares: true } },
  product: {
    select: {
      id: true,
      title: true,
      description: true,
      price: true,
      condition: true,
      images: { take: 1, orderBy: { order: "asc" } },
    },
  },
} satisfies Prisma.PostInclude;

type PostIncludeForViewer = Omit<
  typeof POST_INCLUDE,
  "likes" | "shares" | "savedBy"
> & {
  likes: { where: { userId: string }; take: 1; select: { userId: true } };
  shares: { where: { userId: string }; take: 1; select: { userId: true } };
  savedBy: { where: { userId: string }; take: 1; select: { userId: true } };
};

export function postIncludeForViewer(viewerId?: string): PostIncludeForViewer {
  const interactionWhere = { userId: viewerId ?? "" };
  return {
    ...POST_INCLUDE,
    likes: { where: interactionWhere, take: 1, select: { userId: true } },
    shares: { where: interactionWhere, take: 1, select: { userId: true } },
    savedBy: { where: interactionWhere, take: 1, select: { userId: true } },
  };
}

export type PostPayload = Prisma.PostGetPayload<{
  include: typeof POST_INCLUDE;
}>;

export type PostResponse = Omit<PostPayload, "likes" | "shares" | "savedBy" | "imageBlurHash"> & {
  imageBlurHash?: string;
  isLiked: boolean;
  isSaved: boolean;
  hasReposted: boolean;
};

export const COMMENT_INCLUDE = {
  user: {
    select: { id: true, displayName: true, username: true, avatarUrl: true },
  },
  _count: { select: { commentLikes: true } },
  commentLikes: { take: 1, select: { userId: true } },
  replies: {
    include: {
      user: {
        select: {
          id: true,
          displayName: true,
          username: true,
          avatarUrl: true,
        },
      },
      _count: { select: { commentLikes: true } },
      commentLikes: { take: 1, select: { userId: true } },
    },
    orderBy: { createdAt: "asc" as const },
  },
} satisfies Prisma.CommentInclude;

export type CommentPayload = Prisma.CommentGetPayload<{
  include: typeof COMMENT_INCLUDE;
}>;

export const COMMENT_FLAT_INCLUDE = {
  user: {
    select: { id: true, displayName: true, username: true, avatarUrl: true },
  },
  _count: { select: { commentLikes: true } },
  commentLikes: { take: 1, select: { userId: true } },
} satisfies Prisma.CommentInclude;

export const COMMENT_PAGE_INCLUDE = {
  ...COMMENT_FLAT_INCLUDE,
  replies: {
    where: { deletedAt: null },
    orderBy: { createdAt: "asc" as const },
    take: COMMENT_REPLY_MAX_COUNT,
    include: COMMENT_FLAT_INCLUDE,
  },
} satisfies Prisma.CommentInclude;

export function commentVisibilityWhere(viewerId?: string): Prisma.CommentWhereInput {
  return { OR: [
    { isHidden: false },
    { userId: viewerId ?? '' },
    { post: { userId: viewerId ?? '' } },
  ] };
}

export function commentPageIncludeForViewer(viewerId?: string) {
  const commentLikes = {
    where: { userId: viewerId ?? "" },
    take: 1,
    select: { userId: true },
  } as const;
  return {
    ...COMMENT_PAGE_INCLUDE,
    commentLikes,
    replies: {
      ...COMMENT_PAGE_INCLUDE.replies,
      where: { deletedAt: null, AND: [commentVisibilityWhere(viewerId)] },
      include: { ...COMMENT_FLAT_INCLUDE, commentLikes },
    },
  } satisfies Prisma.CommentInclude;
}

type CommentFlatQueryPayload = Prisma.CommentGetPayload<{
  include: typeof COMMENT_FLAT_INCLUDE;
}>;

export type CommentFlatPayload = Omit<
  CommentFlatQueryPayload,
  "commentLikes"
> & { isLiked: boolean };

export type CommentTree = CommentFlatPayload & { replies: CommentTree[] };

export interface UserPostEntry {
  post: PostResponse;
  repostId: string | null;
  repostedAt: Date | null;
  repostedBy: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
  } | null;
  isReposted: boolean;
  sharesCount: number;
}

export interface FeedQuery {
  userId?: string;
  limit?: number;
  type?: FeedType;
  cursor?: string;
  offset?: number;
  contentFilter?: ContentFilter;
}

export interface FeedRepositoryQuery
  extends Omit<FeedQuery, "cursor"> {
  cursor?: FeedCursor;
}

interface FeedCursorBase {
  userId: string;
  contentFilter: ContentFilter;
  createdAt: string;
  postId: string;
}

export interface FollowingFeedCursor extends FeedCursorBase {
  type: FeedType.FOLLOWING;
  scope: "following-feed";
}

export interface ExploreFeedCursor extends FeedCursorBase {
  type: FeedType.EXPLORE;
  scope: "explore-feed";
  remainingIds: string[];
  hasOlder: boolean;
}

export type FeedCursor = FollowingFeedCursor | ExploreFeedCursor;

export function decodeFeedCursor(value: string): FeedCursor | null {
  if (value.length > 4096) return null;
  try {
    const decoded: unknown = JSON.parse(
      Buffer.from(value, "base64url").toString("utf8"),
    );
    if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) {
      const parsed: Record<string, unknown> = Object.fromEntries(Object.entries(decoded));
      if (typeof parsed.userId === 'string' &&
          isFeedContentFilter(parsed.contentFilter) &&
          typeof parsed.createdAt === 'string' &&
          !Number.isNaN(new Date(parsed.createdAt).getTime()) &&
          typeof parsed.postId === 'string' && parsed.postId.length > 0) {
        const common = {
          userId: parsed.userId,
          contentFilter: parsed.contentFilter,
          createdAt: parsed.createdAt,
          postId: parsed.postId,
        };
        if (parsed.type === FeedType.FOLLOWING && parsed.scope === 'following-feed') {
          return { ...common, type: FeedType.FOLLOWING, scope: 'following-feed' };
        }
        const remainingIds: unknown = parsed.remainingIds;
        if (parsed.type === FeedType.EXPLORE && parsed.scope === 'explore-feed' &&
            Array.isArray(remainingIds) && remainingIds.length <= EXPLORE_CANDIDATE_WINDOW &&
            remainingIds.every((id: unknown): id is string =>
              typeof id === 'string' && id.length > 0 && id.length <= 64) &&
            typeof parsed.hasOlder === 'boolean' &&
            (remainingIds.length > 0 || parsed.hasOlder)) {
          return { ...common, type: FeedType.EXPLORE, scope: 'explore-feed',
            remainingIds, hasOlder: parsed.hasOlder };
        }
      }
    }
    return null;
  } catch {
    return null;
  }
}

function isFeedContentFilter(
  value: unknown,
): value is ContentFilter {
  return value === ContentFilter.ALL || value === ContentFilter.SOCIAL || value === ContentFilter.SELLING;
}

export interface FeedResult {
  posts: PostResponse[];
  hasMore: boolean;
  nextCursor?: string | null;
  nextOffset?: number | null;
}

export interface UserPostsQuery {
  userId: string;
  viewerId?: string;
  limit?: number;
  cursor?: string;
  kind?: ProfileTimelineKind;
}

export enum ProfileTimelineKind {
  POSTS = 'posts',
  REPOSTS = 'reposts',
  PRODUCTS = 'products',
}

export interface UserPostsCursor {
  scope: "user-posts";
  profileUserId: string;
  createdAt: string;
  postId: string;
}

export interface ProfileTimelineCursor {
  createdAt: string;
  eventId: string;
  kind?: ProfileTimelineKind;
}

export interface UserPostsRepositoryQuery {
  userId: string;
  viewerId?: string;
  limit?: number;
  cursor?: UserPostsCursor;
}

export interface SearchPostsQuery {
  query: string;
  filter?: string;
  userId?: string;
  limit?: number;
  cursor?: string;
}

export interface SavedPostsQuery {
  userId: string;
  limit?: number;
  cursor?: string;
}

export interface SavedPostsCursor {
  scope: "saved-posts";
  userId: string;
  createdAt: string;
  savedPostId: string;
}

export interface SavedPostsRepositoryQuery {
  userId: string;
  limit?: number;
  cursor?: SavedPostsCursor;
}

export interface MutationState {
  active: boolean;
  count: number;
}

export interface ShareWithPost {
  id: string;
  post: PostResponse;
  user: { id: string; displayName: string; avatarUrl: string | null };
  createdAt: Date;
}
