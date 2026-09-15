import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { BasePrismaRepository } from "@/shared/infra/prisma/base-prisma.repository";
import { RepositoryResponse } from "@/shared/core/either";
import { CursorPage } from "@/shared/core/pagination";
import {
  PostPayload,
  PostResponse,
  POST_INCLUDE,
  postIncludeForViewer,
  FeedResult,
  FeedCursor,
  FeedRepositoryQuery,
  SearchPostsQuery,
  UserPostsRepositoryQuery,
} from "../../types/social.types";

@Injectable()
export class PrismaPostRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findById(
    id: string,
    viewerId?: string,
  ): RepositoryResponse<PostResponse | null> {
    return this.safeRun(async () => {
      const post = await this.prisma.post.findUnique({
        where: { id },
        include: postIncludeForViewer(viewerId),
      });
      if (post && post.deletedAt !== null) {
        return null;
      }
      return post ? normalizePost(post) : null;
    }, "Erro ao buscar post");
  }

  async findFeed(query: FeedRepositoryQuery): RepositoryResponse<FeedResult> {
    return this.safeRun(async () => {
      const limit = query.limit ?? 20;
      const contentFilter = query.contentFilter ?? "all";
      const where: Prisma.PostWhereInput = { deletedAt: null };

      if (contentFilter === "social") {
        where.type = "REGULAR";
      } else if (contentFilter === "selling") {
        where.type = "PRODUCT";
      }

      const blockFilters = query.userId
        ? [
            { user: { blocksGiven: { none: { blockedId: query.userId } } } },
            { user: { blocksReceived: { none: { blockerId: query.userId } } } },
          ]
        : [];

      if (query.cursor) {
        const cursor = query.cursor;
        where.AND = [
          ...blockFilters,
          {
            OR: [
              { createdAt: { lt: new Date(cursor.createdAt) } },
              {
                createdAt: new Date(cursor.createdAt),
                id: { lt: cursor.postId },
              },
            ],
          },
        ];
      } else if (blockFilters.length > 0) {
        where.AND = blockFilters;
      }

      if (query.type === "following") {
        return this.findFollowingFeed(where, { ...query, contentFilter });
      }
      return this.findExploreFeed(where, query, limit);
    }, "Erro ao buscar feed");
  }

  private async findFollowingFeed(
    where: Prisma.PostWhereInput,
    query: FeedRepositoryQuery,
  ): Promise<FeedResult> {
    const limit = query.limit ?? 20;
    const followingWhere: Prisma.PostWhereInput = { ...where };

    if (query.userId) {
      const follows = await this.prisma.follow.findMany({
        where: { followerId: query.userId },
        select: { followingId: true },
      });
      followingWhere.userId = { in: follows.map((f) => f.followingId) };
    } else {
      followingWhere.userId = { in: [] };
    }

    const posts = await this.prisma.post.findMany({
      where: followingWhere,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit + 1,
      include: postIncludeForViewer(query.userId),
    });

    const hasMore = posts.length > limit;
    const page = posts.slice(0, limit);

    return {
      posts: page.map(normalizePost),
      hasMore,
      nextCursor:
        hasMore && page[page.length - 1]
          ? encodeFeedCursor({
              userId: query.userId ?? "",
              type: "following",
              contentFilter: query.contentFilter ?? "all",
              createdAt: page[page.length - 1].createdAt.toISOString(),
              postId: page[page.length - 1].id,
              scope: "following-feed",
            })
          : null,
    };
  }

  private async findExploreFeed(
    where: Prisma.PostWhereInput,
    query: FeedRepositoryQuery,
    limit: number,
  ): Promise<FeedResult> {
    const CANDIDATE_WINDOW = 300;
    const offset = query.offset ?? 0;

    let followingIds: string[] = [];
    if (query.userId) {
      const follows = await this.prisma.follow.findMany({
        where: { followerId: query.userId },
        select: { followingId: true },
      });
      followingIds = follows.map((f) => f.followingId);
    }

    const candidates = await this.prisma.post.findMany({
      where,
      orderBy: { createdAt: "desc" },
      take: CANDIDATE_WINDOW,
      include: postIncludeForViewer(query.userId),
    });

    const now = Date.now();
    const scored = candidates
      .map((post) => {
        const ageHours = (now - new Date(post.createdAt).getTime()) / 3_600_000;
        const engagement =
          post.likesCount * 3 + post.commentsCount * 5 + post.sharesCount * 4;
        const affinityBoost = followingIds.includes(post.userId) ? 1.5 : 1;
        const score =
          (engagement + 1) * Math.exp(-ageHours / 48) * affinityBoost;
        return { post, score };
      })
      .sort((a, b) => b.score - a.score);

    const page = scored.slice(offset, offset + limit).map(({ post }) => post);
    const hasMore = offset + limit < scored.length;

    return {
      posts: page.map(normalizePost),
      hasMore,
      nextOffset: hasMore ? offset + limit : null,
    };
  }

  async findByUserId(
    query: UserPostsRepositoryQuery,
  ): RepositoryResponse<CursorPage<PostResponse>> {
    return this.safeRun(async () => {
      const limit = query.limit ?? 20;
      const posts = await this.prisma.post.findMany({
        where: {
          userId: query.userId,
          deletedAt: null,
          ...(query.cursor
            ? {
                OR: [
                  { createdAt: { lt: new Date(query.cursor.createdAt) } },
                  {
                    createdAt: new Date(query.cursor.createdAt),
                    id: { lt: query.cursor.postId },
                  },
                ],
              }
            : {}),
        },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        take: limit + 1,
        include: postIncludeForViewer(query.viewerId),
      });
      const hasMore = posts.length > limit;
      const page = posts.slice(0, limit).map(normalizePost);
      const last = page[page.length - 1];
      return {
        items: page,
        hasMore,
        nextCursor:
          hasMore && last
            ? Buffer.from(
                JSON.stringify({
                  scope: "user-posts",
                  profileUserId: query.userId,
                  createdAt: last.createdAt.toISOString(),
                  postId: last.id,
                }),
                "utf8",
              ).toString("base64url")
            : null,
      };
    }, "Erro ao buscar posts do usuário");
  }

  async searchPosts(
    query: SearchPostsQuery,
  ): RepositoryResponse<PostResponse[]> {
    return this.safeRun(async () => {
      const where: Prisma.PostWhereInput = {
        deletedAt: null,
        content: { contains: query.query, mode: "insensitive" },
      };

      if (query.userId) {
        if (query.filter === "following") {
          where.user = {
            followers: {
              some: {
                followerId: query.userId,
              },
            },
          };
        } else if (query.filter === "followers") {
          where.user = {
            following: {
              some: {
                followingId: query.userId,
              },
            },
          };
        }
      }

      const posts = await this.prisma.post.findMany({
        where,
        orderBy: { createdAt: "desc" },
        take: query.limit ?? 20,
        ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}),
        include: postIncludeForViewer(query.userId),
      });
      return posts.map(normalizePost);
    }, "Erro ao buscar posts");
  }

  async create(data: Record<string, unknown>): RepositoryResponse<PostPayload> {
    return this.safeRun(async () => {
      const post = await this.prisma.post.create({
        data: data as Prisma.PostCreateInput,
        include: POST_INCLUDE,
      });
      return post as PostPayload;
    }, "Erro ao criar post");
  }

  async update(
    id: string,
    data: Record<string, unknown>,
  ): RepositoryResponse<unknown> {
    return this.safeRun(
      () =>
        this.prisma.post.update({
          where: { id },
          data: data as Prisma.PostUpdateInput,
        }),
      "Erro ao atualizar post",
    );
  }

  async createMentions(
    postId: string,
    mentionedUserIds: string[],
  ): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.postMention.createMany({
        data: mentionedUserIds.map((mentionedUserId) => ({
          postId,
          mentionedUserId,
        })),
        skipDuplicates: true,
      });
    }, "Erro ao criar menções");
  }

  async softDelete(id: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.post.update({
        where: { id },
        data: { deletedAt: new Date() },
      });
    }, "Erro ao apagar post");
  }

  async findSaved(query: {
    userId: string;
    limit?: number;
    cursor?: string;
  }): RepositoryResponse<FeedResult> {
    return this.safeRun(async () => {
      const limit = query.limit ?? 20;
      const saved = await this.prisma.savedPost.findMany({
        where: { userId: query.userId, post: { deletedAt: null } },
        orderBy: { createdAt: "desc" },
        take: limit + 1,
        ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
        include: { post: { include: postIncludeForViewer(query.userId) } },
      });
      const hasMore = saved.length > limit;
      const page = saved.slice(0, limit);
      return {
        posts: page.map(({ post }) => normalizePost(post)),
        hasMore,
        nextCursor: hasMore ? (page[page.length - 1]?.id ?? null) : null,
      };
    }, "Erro ao buscar posts salvos");
  }

}

export function normalizePost(post: PostPayload): PostResponse {
  const { likes, savedBy, shares, ...response } = post;
  return {
    ...response,
    imageUrl: post.imageUrl ?? post.product?.images[0]?.url ?? null,
    likesCount: post._count.likes,
    commentsCount: post._count.comments,
    sharesCount: post._count.shares,
    isLiked: likes.length > 0,
    isSaved: savedBy.length > 0,
    hasReposted: shares.length > 0,
  };
}

function encodeFeedCursor(cursor: FeedCursor): string {
  return Buffer.from(JSON.stringify(cursor), "utf8").toString("base64url");
}
