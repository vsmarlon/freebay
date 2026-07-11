import { Prisma } from '@prisma/client';

export const POST_INCLUDE = {
  user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
  likes: { take: 3, select: { userId: true } },
  _count: { select: { likes: true, comments: true, shares: true } },
} satisfies Prisma.PostInclude;

export const POST_INCLUDE_FULL = {
  ...POST_INCLUDE,
  product: { include: { images: { take: 1 } } },
} satisfies Prisma.PostInclude;

export type PostPayload = Prisma.PostGetPayload<{ include: typeof POST_INCLUDE }>;

export const COMMENT_INCLUDE = {
  user: { select: { id: true, displayName: true, avatarUrl: true } },
  _count: { select: { commentLikes: true } },
  replies: {
    include: {
      user: { select: { id: true, displayName: true, avatarUrl: true } },
      _count: { select: { commentLikes: true } },
    },
    orderBy: { createdAt: 'asc' as const },
  },
} satisfies Prisma.CommentInclude;

export type CommentPayload = Prisma.CommentGetPayload<{ include: typeof COMMENT_INCLUDE }>;

export const COMMENT_FLAT_INCLUDE = {
  user: { select: { id: true, displayName: true, avatarUrl: true } },
  _count: { select: { commentLikes: true } },
} satisfies Prisma.CommentInclude;

export type CommentFlatPayload = Prisma.CommentGetPayload<{ include: typeof COMMENT_FLAT_INCLUDE }>;

export type CommentTree = CommentFlatPayload & { replies: CommentTree[] };

export interface UserPostEntry {
  post: PostPayload;
  repostedAt: Date | null;
  repostedBy: { id: string; displayName: string; avatarUrl: string | null } | null;
  isReposted: boolean;
  sharesCount: number;
}
