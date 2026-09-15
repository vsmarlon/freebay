import { Prisma } from "@prisma/client";

export const POST_INCLUDE = {
  user: {
    select: {
      id: true,
      displayName: true,
      username: true,
      avatarUrl: true,
      isVerified: true,
    },
  },
  likes: { take: 1, select: { userId: true } },
  shares: { take: 1, select: { userId: true } },
  savedBy: { take: 1, select: { userId: true } },
  _count: { select: { likes: true, comments: true, shares: true } },
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

export type PostResponse = Omit<PostPayload, "likes" | "shares" | "savedBy"> & {
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
    take: 50,
    include: COMMENT_FLAT_INCLUDE,
  },
} satisfies Prisma.CommentInclude;

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
  type?: "explore" | "following";
  cursor?: string;
  offset?: number;
  contentFilter?: "all" | "social" | "selling";
}

export interface FeedRepositoryQuery
  extends Omit<FeedQuery, "cursor"> {
  cursor?: FeedCursor;
}

export interface FeedCursor {
  userId: string;
  type: "following";
  contentFilter: "all" | "social" | "selling";
  createdAt: string;
  postId: string;
  scope: "following-feed";
}

export function decodeFeedCursor(value: string): FeedCursor | null {
  try {
    const parsed: unknown = JSON.parse(
      Buffer.from(value, "base64url").toString("utf8"),
    );
    if (
      typeof parsed !== "object" ||
      parsed === null ||
      !("userId" in parsed) ||
      !("type" in parsed) ||
      !("contentFilter" in parsed) ||
      !("createdAt" in parsed) ||
      !("postId" in parsed) ||
      !("scope" in parsed) ||
      typeof parsed.userId !== "string" ||
      parsed.type !== "following" ||
      !isFeedContentFilter(parsed.contentFilter) ||
      parsed.scope !== "following-feed" ||
      typeof parsed.createdAt !== "string" ||
      Number.isNaN(new Date(parsed.createdAt).getTime()) ||
      typeof parsed.postId !== "string"
    ) {
      return null;
    }
    return {
      userId: parsed.userId,
      type: "following",
      contentFilter: parsed.contentFilter,
      createdAt: parsed.createdAt,
      postId: parsed.postId,
      scope: "following-feed",
    };
  } catch {
    return null;
  }
}

function isFeedContentFilter(
  value: unknown,
): value is FeedCursor["contentFilter"] {
  return value === "all" || value === "social" || value === "selling";
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
}

export interface UserPostsCursor {
  scope: "user-posts";
  profileUserId: string;
  createdAt: string;
  postId: string;
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
