import { RepositoryResponse } from '@/shared/core/either';
import { PostPayload } from '../../types/social.types';

export interface FeedQuery {
  userId?: string;
  limit?: number;
  type?: 'explore' | 'following';
}

export interface UserPostsQuery {
  userId: string;
  limit?: number;
  cursor?: string;
}

export interface SearchPostsQuery {
  query: string;
  filter?: string;
  userId?: string;
  limit?: number;
  cursor?: string;
}

export abstract class PostRepository {
  abstract findById(id: string): RepositoryResponse<PostPayload | null>;
  abstract findFeed(query: FeedQuery): RepositoryResponse<PostPayload[]>;
  abstract findByUserId(query: UserPostsQuery): RepositoryResponse<PostPayload[]>;
  abstract searchPosts(query: SearchPostsQuery): RepositoryResponse<PostPayload[]>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<PostPayload>;
  abstract update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown>;
  abstract createMentions(postId: string, mentionedUserIds: string[]): RepositoryResponse<void>;
}
