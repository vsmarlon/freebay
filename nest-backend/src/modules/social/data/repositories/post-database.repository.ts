import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { FeedResult, PostPayload, PostResponse, POST_INCLUDE, postIncludeForViewer, SearchPostsQuery, UserPostsRepositoryQuery, ProfileTimelineCursor, UserPostEntry } from '../../types/social.types';
import { CursorPage } from '@/shared/core/pagination';
import { PostQueryHelpers, normalizePost, postVisibilityWhere } from './post-query-helpers';

@Injectable()
export class PrismaPostRepository {
  private readonly queries: PostQueryHelpers;

  constructor(private readonly prisma: PrismaService) {
    this.queries = new PostQueryHelpers(prisma);
  }

  findById(id: string, viewerId?: string): RepositoryResponse<PostResponse | null> { return this.queries.findById(id, viewerId); }
  findFeed(query: import('../../types/social.types').FeedRepositoryQuery): RepositoryResponse<FeedResult> { return this.queries.findFeed(query); }
  findByUserId(query: UserPostsRepositoryQuery): RepositoryResponse<CursorPage<PostResponse>> { return this.queries.findByUserId(query); }
  findTimelineByUserId(query: { userId: string; viewerId?: string; limit: number; cursor?: ProfileTimelineCursor }): RepositoryResponse<CursorPage<UserPostEntry>> { return this.queries.findTimelineByUserId(query); }
  searchPosts(query: SearchPostsQuery): RepositoryResponse<PostResponse[]> { return this.queries.searchPosts(query); }

  async create(data: Prisma.PostCreateInput): RepositoryResponse<PostPayload> {
    return repositoryResponse(async () => {
      return this.prisma.post.create({ data, include: POST_INCLUDE });
    }, 'Erro ao criar post');
  }

  async update(id: string, data: Prisma.PostUpdateInput): RepositoryResponse<unknown> {
    return repositoryResponse(() => this.prisma.post.update({ where: { id }, data }), 'Erro ao atualizar post');
  }

  async createMentions(postId: string, mentionedUserIds: string[]): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.postMention.createMany({ data: mentionedUserIds.map((mentionedUserId) => ({ postId, mentionedUserId })), skipDuplicates: true });
    }, 'Erro ao criar menções');
  }

  async softDelete(id: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.post.update({ where: { id }, data: { deletedAt: new Date() } });
    }, 'Erro ao apagar post');
  }

  async findSaved(query: { userId: string; limit?: number; cursor?: string }): RepositoryResponse<FeedResult> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? 20;
       const saved = await this.prisma.savedPost.findMany({ where: { userId: query.userId, post: { deletedAt: null, AND: [postVisibilityWhere(query.userId)] } }, orderBy: { createdAt: 'desc' }, take: limit + 1, ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}), include: { post: { include: postIncludeForViewer(query.userId) } } });
      const hasMore = saved.length > limit;
      const page = saved.slice(0, limit);
      return { posts: page.map(({ post }) => normalizePost(post)), hasMore, nextCursor: hasMore ? (page[page.length - 1]?.id ?? null) : null };
    }, 'Erro ao buscar posts salvos');
  }
}

export { normalizePost } from './post-query-helpers';
