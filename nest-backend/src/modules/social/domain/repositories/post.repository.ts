import { RepositoryResponse } from '@/shared/core/either';
import { PostPayload, FeedQuery, FeedResult, UserPostsQuery, SearchPostsQuery } from '../../types/social.types';

export abstract class PostRepository {
  abstract findById(id: string): RepositoryResponse<PostPayload | null>;
  abstract findFeed(query: FeedQuery): RepositoryResponse<FeedResult>;
  abstract findByUserId(query: UserPostsQuery): RepositoryResponse<PostPayload[]>;
  abstract searchPosts(query: SearchPostsQuery): RepositoryResponse<PostPayload[]>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<PostPayload>;
  abstract update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown>;
  abstract createMentions(postId: string, mentionedUserIds: string[]): RepositoryResponse<void>;
  abstract softDelete(id: string): RepositoryResponse<void>;
}
