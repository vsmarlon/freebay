import { PostType, Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import {
  FeedCursor,
  FeedRepositoryQuery,
  FeedResult,
  PostPayload,
  PostResponse,
  SearchPostsQuery,
  UserPostsRepositoryQuery,
  UserPostEntry,
  ProfileTimelineCursor,
  postIncludeForViewer,
  ContentFilter,
  FeedType,
  SearchFilter,
  EXPLORE_CANDIDATE_WINDOW,
  SOCIAL_DEFAULT_PAGE_SIZE,
} from '../../types/social.types';

export class PostQueryHelpers {
  constructor(private readonly prisma: PrismaService) {
  }

  async findFeed(query: FeedRepositoryQuery): RepositoryResponse<FeedResult> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
      const contentFilter = query.contentFilter ?? ContentFilter.ALL;
      const where: Prisma.PostWhereInput = { deletedAt: null };
      if (contentFilter === ContentFilter.SOCIAL) where.type = PostType.REGULAR;
      else if (contentFilter === ContentFilter.SELLING) where.type = PostType.PRODUCT;

      const blockFilters = query.userId ? [
        { user: { blocksGiven: { none: { blockedId: query.userId } } } },
        { user: { blocksReceived: { none: { blockerId: query.userId } } } },
      ] : [];
      if (query.cursor) {
        where.AND = [...blockFilters, { OR: [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.postId } },
        ] }];
      } else if (blockFilters.length > 0) where.AND = blockFilters;
      return query.type === FeedType.FOLLOWING
        ? this.findFollowingFeed(where, { ...query, contentFilter })
        : this.findExploreFeed(where, query, limit);
    }, 'Erro ao buscar feed');
  }

  private async findFollowingFeed(where: Prisma.PostWhereInput, query: FeedRepositoryQuery): Promise<FeedResult> {
    const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
    const followingWhere: Prisma.PostWhereInput = { ...where };
    const follows = query.userId ? await this.prisma.follow.findMany({ where: { followerId: query.userId }, select: { followingId: true } }) : [];
    followingWhere.userId = { in: follows.map((follow) => follow.followingId) };
    const posts = await this.prisma.post.findMany({ where: followingWhere, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1, include: postIncludeForViewer(query.userId) });
    const hasMore = posts.length > limit;
    const page = posts.slice(0, limit);
    return {
      posts: page.map(normalizePost),
      hasMore,
      nextCursor: hasMore && page[page.length - 1] ? encodeFeedCursor({
        userId: query.userId ?? '', type: FeedType.FOLLOWING, contentFilter: query.contentFilter ?? ContentFilter.ALL,
        createdAt: page[page.length - 1].createdAt.toISOString(), postId: page[page.length - 1].id, scope: 'following-feed',
      }) : null,
    };
  }

  private async findExploreFeed(where: Prisma.PostWhereInput, query: FeedRepositoryQuery, limit: number): Promise<FeedResult> {
    const followingIds = query.userId
      ? new Set((await this.prisma.follow.findMany({ where: { followerId: query.userId }, select: { followingId: true } })).map((follow) => follow.followingId))
      : new Set<string>();
      const candidates = await this.prisma.post.findMany({ where, orderBy: { createdAt: 'desc' }, take: EXPLORE_CANDIDATE_WINDOW, include: postIncludeForViewer(query.userId) });
    const now = Date.now();
    const scored = candidates.map((post) => {
      const ageHours = (now - new Date(post.createdAt).getTime()) / 3_600_000;
      const engagement = post.likesCount * 3 + post.commentsCount * 5 + post.sharesCount * 4;
      const affinityBoost = followingIds.has(post.userId) ? 1.5 : 1;
      return { post, score: (engagement + 1) * Math.exp(-ageHours / 48) * affinityBoost };
    }).sort((a, b) => b.score - a.score);
    const offset = query.offset ?? 0;
    const page = scored.slice(offset, offset + limit).map(({ post }) => post);
    const hasMore = offset + limit < scored.length;
    return { posts: page.map(normalizePost), hasMore, nextOffset: hasMore ? offset + limit : null };
  }

  async findById(id: string, viewerId?: string): RepositoryResponse<PostResponse | null> {
    return repositoryResponse(async () => {
      const post = await this.prisma.post.findUnique({ where: { id }, include: postIncludeForViewer(viewerId) });
      return post && post.deletedAt === null ? normalizePost(post) : null;
    }, 'Erro ao buscar post');
  }

  async findByUserId(query: UserPostsRepositoryQuery): RepositoryResponse<CursorPage<PostResponse>> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
      const posts = await this.prisma.post.findMany({
        where: { userId: query.userId, deletedAt: null, ...(query.cursor ? { OR: [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.postId } },
        ] } : {}) },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1, include: postIncludeForViewer(query.viewerId),
      });
      const hasMore = posts.length > limit;
      const page = posts.slice(0, limit).map(normalizePost);
      const last = page[page.length - 1];
      return { items: page, hasMore, nextCursor: hasMore && last ? Buffer.from(JSON.stringify({ scope: 'user-posts', profileUserId: query.userId, createdAt: last.createdAt.toISOString(), postId: last.id }), 'utf8').toString('base64url') : null };
    }, 'Erro ao buscar posts do usuário');
  }

  findTimelineByUserId(query: { userId: string; viewerId?: string; limit: number; cursor?: ProfileTimelineCursor }): RepositoryResponse<CursorPage<UserPostEntry>> {
    return repositoryResponse(async () => {
      const boundary = query.cursor ? {
        OR: [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.eventId } },
        ],
      } : {};
      const [posts, shares] = await Promise.all([
        this.prisma.post.findMany({
          where: { userId: query.userId, deletedAt: null, ...boundary },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: query.limit + 1,
          include: postIncludeForViewer(query.viewerId),
        }),
        this.prisma.share.findMany({
          where: { userId: query.userId, post: { deletedAt: null }, ...boundary },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: query.limit + 1,
          include: {
            post: { include: postIncludeForViewer(query.viewerId) },
            user: { select: { id: true, displayName: true, avatarUrl: true } },
          },
        }),
      ]);
      const events = [
        ...posts.map((post) => ({
          id: post.id,
          createdAt: post.createdAt,
          entry: {
            post: normalizePost(post), repostId: null, repostedAt: null,
            repostedBy: null, isReposted: false, sharesCount: post.sharesCount,
          } satisfies UserPostEntry,
        })),
        ...shares.map((share) => ({
          id: share.id,
          createdAt: share.createdAt,
          entry: {
            post: normalizePost(share.post), repostId: share.id,
            repostedAt: share.createdAt, repostedBy: share.user,
            isReposted: true, sharesCount: share.post.sharesCount,
          } satisfies UserPostEntry,
        })),
      ].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime() || b.id.localeCompare(a.id));
      const page = events.slice(0, query.limit);
      const hasMore = events.length > query.limit;
      const last = page[page.length - 1];
      return {
        items: page.map(({ entry }) => entry),
        hasMore,
        nextCursor: hasMore && last
          ? Buffer.from(`${query.userId}|${last.createdAt.toISOString()}|${last.id}`).toString('base64url')
          : null,
      };
    }, 'Erro ao buscar timeline do perfil');
  }

  async searchPosts(query: SearchPostsQuery): RepositoryResponse<PostResponse[]> {
    return repositoryResponse(async () => {
      const where: Prisma.PostWhereInput = { deletedAt: null, content: { contains: query.query, mode: 'insensitive' } };
      if (query.userId && query.filter === SearchFilter.FOLLOWING) where.user = { followers: { some: { followerId: query.userId } } };
      else if (query.userId && query.filter === SearchFilter.FOLLOWERS) where.user = { following: { some: { followingId: query.userId } } };
      const posts = await this.prisma.post.findMany({ where, orderBy: { createdAt: 'desc' }, take: query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE, ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}), include: postIncludeForViewer(query.userId) });
      return posts.map(normalizePost);
    }, 'Erro ao buscar posts');
  }
}

export function normalizePost(post: PostPayload): PostResponse {
  const { likes, savedBy, shares, ...response } = post;
  return { ...response, imageUrl: post.imageUrl ?? post.product?.images[0]?.url ?? null, likesCount: post._count.likes, commentsCount: post._count.comments, sharesCount: post._count.shares, isLiked: likes.length > 0, isSaved: savedBy.length > 0, hasReposted: shares.length > 0 };
}

export function encodeFeedCursor(cursor: FeedCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}
