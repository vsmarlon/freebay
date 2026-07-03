import { RepositoryResponse } from '@/shared/core/either';

export abstract class LikeRepository {
  abstract findPostLike(userId: string, postId: string): RepositoryResponse<{ id: string } | null>;
  abstract createLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }>;
  abstract deletePostLikeByUser(userId: string, postId: string): RepositoryResponse<void>;
  abstract findLikedByUserId(userId: string): RepositoryResponse<unknown[]>;
  abstract findCommentLike(userId: string, commentId: string): RepositoryResponse<{ id: string } | null>;
  abstract createCommentLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }>;
  abstract deleteCommentLike(data: { userId: string; commentId: string }): RepositoryResponse<void>;
}
