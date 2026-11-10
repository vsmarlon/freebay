import { PostType, Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { isValidBlurHash } from '@/shared/utils/blurhash.utils';
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
  ProfileTimelineKind,
} from '../../types/social.types';

export class PostQueryHelpers {
  constructor(private readonly prisma: PrismaService) {
  }

  async findFeed(query: FeedRepositoryQuery): RepositoryResponse<FeedResult> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
      const contentFilter = query.contentFilter ?? ContentFilter.ALL;
      const where: Prisma.PostWhereInput = { deletedAt: null, AND: [postVisibilityWhere(query.userId)] };
      if (contentFilter === ContentFilter.SOCIAL) where.type = PostType.REGULAR;
      else if (contentFilter === ContentFilter.SELLING) where.type = PostType.PRODUCT;

      if (query.cursor?.scope === 'following-feed') {
        where.OR = [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.postId } },
        ];
      }
      return query.type === FeedType.FOLLOWING
        ? this.findFollowingFeed(where, { ...query, contentFilter })
        : this.findExploreFeed(where, query, limit);
    }, 'Erro ao buscar feed');
  }

  private async findFollowingFeed(where: Prisma.PostWhereInput, query: FeedRepositoryQuery): Promise<FeedResult> {
    const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
    const followingWhere: Prisma.PostWhereInput = { ...where };
    followingWhere.user = {
      ...visiblePostAuthor(query.userId ?? ''),
      followers: { some: { followerId: query.userId ?? '' } },
    };
    const posts = await this.prisma.post.findMany({ where: followingWhere, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1, include: postIncludeForViewer(query.userId) });
    const hasMore = posts.length > limit;
    const page = posts.slice(0, limit);
    return {
      posts: await normalizePostsForViewer(page, query.userId, this.prisma),
      hasMore,
      nextCursor: hasMore && page[page.length - 1] ? encodeFeedCursor({
        userId: query.userId ?? '', type: FeedType.FOLLOWING, contentFilter: query.contentFilter ?? ContentFilter.ALL,
        createdAt: page[page.length - 1].createdAt.toISOString(), postId: page[page.length - 1].id, scope: 'following-feed',
      }) : null,
    };
  }

  private async findExploreFeed(where: Prisma.PostWhereInput, query: FeedRepositoryQuery, limit: number): Promise<FeedResult> {
    const cursor = query.cursor?.scope === 'explore-feed' ? query.cursor : null;
    if (cursor && cursor.remainingIds.length > 0) {
      const rows = await this.prisma.post.findMany({
        where: { ...where, id: { in: cursor.remainingIds } },
        take: cursor.remainingIds.length,
        include: postIncludeForViewer(query.userId),
      });
      const byId = new Map(rows.map((post) => [post.id, post]));
      const page = cursor.remainingIds.slice(0, limit)
        .map((id) => byId.get(id))
        .filter((post): post is PostPayload => post != null);
      const remainingIds = cursor.remainingIds.slice(limit);
      const hasMore = remainingIds.length > 0 || cursor.hasOlder;
      return {
        posts: await normalizePostsForViewer(page, query.userId, this.prisma), hasMore,
        nextCursor: hasMore ? encodeFeedCursor({ ...cursor, remainingIds }) : null,
      };
    }
    if (cursor) {
      where.OR = [
        { createdAt: { lt: new Date(cursor.createdAt) } },
        { createdAt: new Date(cursor.createdAt), id: { lt: cursor.postId } },
      ];
    }
    const rows = await this.prisma.post.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: EXPLORE_CANDIDATE_WINDOW + 1,
      include: postIncludeForViewer(query.userId),
    });
    const hasOlder = rows.length > EXPLORE_CANDIDATE_WINDOW;
    const candidates = rows.slice(0, EXPLORE_CANDIDATE_WINDOW);
    if (candidates.length === 0) return { posts: [], hasMore: false, nextCursor: null };
    const followingIds = query.userId
      ? new Set((await this.prisma.follow.findMany({
          where: { followerId: query.userId, followingId: { in: [...new Set(candidates.map((post) => post.userId))] } },
          select: { followingId: true },
        })).map((follow) => follow.followingId))
      : new Set<string>();
    const now = Date.now();
    const scored = candidates.map((post) => {
      const ageHours = (now - new Date(post.createdAt).getTime()) / 3_600_000;
      const engagement = post.likesCount * 3 + post.commentsCount * 5 + post.sharesCount * 4;
      const affinityBoost = followingIds.has(post.userId) ? 1.5 : 1;
      return { post, score: (engagement + 1) * Math.exp(-ageHours / 48) * affinityBoost };
    }).sort((a, b) => b.score - a.score);
    // ponytail: this scan is bounded to 60 candidates; use a bucketed merge if the window grows.
    for (let i = 2; i < scored.length; i++) {
      if (scored[i].post.userId !== scored[i - 1].post.userId ||
          scored[i].post.userId !== scored[i - 2].post.userId) continue;
      const alternative = scored.findIndex((entry, index) =>
        index > i && entry.post.userId !== scored[i].post.userId,
      );
      if (alternative !== -1) scored.splice(i, 0, scored.splice(alternative, 1)[0]);
    }
    const page = scored.slice(0, limit).map(({ post }) => post);
    const remainingIds = scored.slice(limit).map(({ post }) => post.id);
    const hasMore = remainingIds.length > 0 || hasOlder;
    const boundary = candidates[candidates.length - 1];
    return {
      posts: await normalizePostsForViewer(page, query.userId, this.prisma),
      hasMore,
      nextCursor: hasMore ? encodeFeedCursor({
        userId: query.userId ?? '', type: FeedType.EXPLORE,
        contentFilter: query.contentFilter ?? ContentFilter.ALL,
        createdAt: boundary.createdAt.toISOString(), postId: boundary.id,
        scope: 'explore-feed', remainingIds, hasOlder,
      }) : null,
    };
  }

  async findById(id: string, viewerId?: string): RepositoryResponse<PostResponse | null> {
    return repositoryResponse(async () => {
      const post = await this.prisma.post.findUnique({
        where: { id, AND: [postVisibilityWhere(viewerId)] },
        include: postIncludeForViewer(viewerId),
      });
      return post && post.deletedAt === null ? (await normalizePostsForViewer([post], viewerId, this.prisma))[0] : null;
    }, 'Erro ao buscar post');
  }

  async findByUserId(query: UserPostsRepositoryQuery): RepositoryResponse<CursorPage<PostResponse>> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE;
      const posts = await this.prisma.post.findMany({
        where: { userId: query.userId, deletedAt: null,
          AND: [postVisibilityWhere(query.viewerId)],
          ...(query.cursor ? { OR: [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.postId } },
        ] } : {}) },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1, include: postIncludeForViewer(query.viewerId),
      });
      const hasMore = posts.length > limit;
      const page = await normalizePostsForViewer(posts.slice(0, limit), query.viewerId, this.prisma);
      const last = page[page.length - 1];
      return { items: page, hasMore, nextCursor: hasMore && last ? Buffer.from(JSON.stringify({ scope: 'user-posts', profileUserId: query.userId, createdAt: last.createdAt.toISOString(), postId: last.id }), 'utf8').toString('base64url') : null };
    }, 'Erro ao buscar posts do usuário');
  }

  findTimelineByUserId(query: { userId: string; viewerId?: string; limit: number; cursor?: ProfileTimelineCursor; kind?: ProfileTimelineKind }): RepositoryResponse<CursorPage<UserPostEntry>> {
    return repositoryResponse(async () => {
      const boundary = query.cursor ? {
        OR: [
          { createdAt: { lt: new Date(query.cursor.createdAt) } },
          { createdAt: new Date(query.cursor.createdAt), id: { lt: query.cursor.eventId } },
        ],
      } : {};
      const [posts, shares] = await Promise.all([
        query.kind === ProfileTimelineKind.REPOSTS ? Promise.resolve([]) : this.prisma.post.findMany({
          where: { userId: query.userId, deletedAt: null, ...boundary,
            ...(query.kind === ProfileTimelineKind.POSTS ? { type: PostType.REGULAR } : query.kind === ProfileTimelineKind.PRODUCTS ? { type: PostType.PRODUCT } : {}),
            AND: [postVisibilityWhere(query.viewerId)],
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: query.limit + 1,
          include: postIncludeForViewer(query.viewerId),
        }),
        query.kind === ProfileTimelineKind.POSTS || query.kind === ProfileTimelineKind.PRODUCTS ? Promise.resolve([]) : this.prisma.share.findMany({
          where: { userId: query.userId,
            post: { deletedAt: null, AND: [postVisibilityWhere(query.viewerId)] },
            ...boundary,
            ...(query.viewerId ? { user: visiblePostAuthor(query.viewerId) } : {}),
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: query.limit + 1,
          include: {
            post: { include: postIncludeForViewer(query.viewerId) },
            user: { select: { id: true, displayName: true, avatarUrl: true } },
          },
        }),
      ]);
      const normalizedPosts = await normalizePostsForViewer(posts, query.viewerId, this.prisma);
      const normalizedShares = await normalizePostsForViewer(shares.map((share) => share.post), query.viewerId, this.prisma);
      const normalizedPostById = new Map(normalizedPosts.map((post) => [post.id, post]));
      const normalizedShareById = new Map(normalizedShares.map((post) => [post.id, post]));
      const events = [
        ...posts.map((post) => ({
          id: post.id,
          createdAt: post.createdAt,
          entry: {
            post: normalizedPostById.get(post.id)!, repostId: null, repostedAt: null,
            repostedBy: null, isReposted: false, sharesCount: post.sharesCount,
          } satisfies UserPostEntry,
        })),
        ...shares.map((share) => ({
          id: share.id,
          createdAt: share.createdAt,
          entry: {
            post: normalizedShareById.get(share.post.id)!, repostId: share.id,
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
          ? Buffer.from(`${query.userId}|${last.createdAt.toISOString()}|${last.id}${query.kind ? `|${query.kind}` : ''}`).toString('base64url')
          : null,
      };
    }, 'Erro ao buscar timeline do perfil');
  }

  async searchPosts(query: SearchPostsQuery): RepositoryResponse<PostResponse[]> {
    return repositoryResponse(async () => {
      const where: Prisma.PostWhereInput = { deletedAt: null, content: { contains: query.query, mode: 'insensitive' }, AND: [postVisibilityWhere(query.userId)] };
      if (query.userId) {
        const author = visiblePostAuthor(query.userId);
        if (query.filter === SearchFilter.FOLLOWING) author.followers = { some: { followerId: query.userId } };
        else if (query.filter === SearchFilter.FOLLOWERS) author.following = { some: { followingId: query.userId } };
        where.user = author;
      }
      const posts = await this.prisma.post.findMany({ where, orderBy: { createdAt: 'desc' }, take: query.limit ?? SOCIAL_DEFAULT_PAGE_SIZE, ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}), include: postIncludeForViewer(query.userId) });
      return normalizePostsForViewer(posts, query.userId, this.prisma);
    }, 'Erro ao buscar posts');
  }
}

export function visiblePostAuthor(viewerId: string): Prisma.UserWhereInput {
  return {
    blocksGiven: { none: { blockedId: viewerId } },
    blocksReceived: { none: { blockerId: viewerId } },
  };
}

export function postVisibilityWhere(viewerId?: string): Prisma.PostWhereInput {
  if (!viewerId) return { audience: 'EVERYONE' };
  return {
    OR: [
      { userId: viewerId },
      { audience: 'EVERYONE', user: visiblePostAuthor(viewerId) },
      { audience: 'CLOSE_FRIENDS', user: {
        ...visiblePostAuthor(viewerId),
        closeFriendsGiven: { some: { memberId: viewerId } },
        OR: [
          { following: { some: { followingId: viewerId } } },
          { followers: { some: { followerId: viewerId } } },
        ],
      } },
    ],
  };
}

export function normalizePost(post: PostPayload): PostResponse {
  const { likes, savedBy, shares, clientRequestId: _requestId, clientRequestHash: _requestHash,
    quoteSourcePostId: _sourcePostId, quoteSourceCommentId: _sourceCommentId, media: postMedia, ...response } = post;
  const media = (postMedia.length > 0 ? postMedia : post.product?.media ?? []).map(({ blurHash, ...item }) => ({
    ...item,
    ...(post.audience === 'EVERYONE' && isValidBlurHash(blurHash) ? { blurHash } : {}),
  }));
  return {
    ...response,
    media,
    likesCount: post._count.likes,
    commentsCount: post._count.comments,
    sharesCount: post._count.shares,
    isLiked: likes.length > 0,
    isSaved: savedBy.length > 0,
    hasReposted: shares.length > 0,
    isQuote: post.isQuote,
    quoteSource: null,
  };
}

export async function normalizePostsForViewer(posts: readonly PostPayload[], viewerId: string | undefined, prisma: PrismaService): Promise<PostResponse[]> {
  const normalized = posts.map(normalizePost);
  const postSourceIds = [...new Set(posts.flatMap((post) => post.quoteSourcePostId ? [post.quoteSourcePostId] : []))];
  const commentSourceIds = [...new Set(posts.flatMap((post) => post.quoteSourceCommentId ? [post.quoteSourceCommentId] : []))];
  const [postSources, commentSources] = await Promise.all([
    postSourceIds.length ? prisma.post.findMany({
      where: { id: { in: postSourceIds }, deletedAt: null, audience: 'EVERYONE', AND: [postVisibilityWhere(viewerId)] },
      include: postIncludeForViewer(viewerId),
    }) : Promise.resolve([]),
    commentSourceIds.length ? prisma.comment.findMany({
      where: { id: { in: commentSourceIds }, deletedAt: null, isHidden: false, authorHiddenAt: null,
        post: { deletedAt: null, audience: 'EVERYONE', AND: [postVisibilityWhere(viewerId)] },
        ...(viewerId ? { user: visiblePostAuthor(viewerId) } : {}),
      },
      include: { user: { select: { id: true, displayName: true, username: true, avatarUrl: true } }, commentLikes: { where: { userId: viewerId ?? '' }, take: 1, select: { userId: true } } },
    }) : Promise.resolve([]),
  ]);
  const sourcePosts = new Map(postSources.map((post) => [post.id, normalizePost(post)]));
  const sourceComments = new Map(commentSources.map((comment) => [comment.id, comment]));
  return normalized.map((response, index) => {
    const post = posts[index];
    if (post.quoteSourcePostId) {
      const source = sourcePosts.get(post.quoteSourcePostId);
      if (source) response.quoteSource = { kind: 'post', id: source.id, post: {
        id: source.id, content: source.content, media: source.media,
        type: source.type, audience: source.audience, userId: source.userId, createdAt: source.createdAt,
        user: source.user, likesCount: source.likesCount, commentsCount: source.commentsCount, sharesCount: source.sharesCount,
      } };
    } else if (post.quoteSourceCommentId) {
      const source = sourceComments.get(post.quoteSourceCommentId);
      if (source) response.quoteSource = { kind: 'comment', id: source.id, postId: source.postId, comment: {
        id: source.id, postId: source.postId, parentId: source.parentId, userId: source.userId,
        content: source.content, createdAt: source.createdAt, deletedAt: source.deletedAt,
        likesCount: source.likesCount, user: source.user, isLiked: source.commentLikes.length > 0,
      } };
    }
    return response;
  });
}

export function encodeFeedCursor(cursor: FeedCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}
