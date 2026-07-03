import { RepositoryResponse } from '@/shared/core/either';
import { CommentPayload } from '../../types/social.types';

export abstract class CommentRepository {
  abstract findByPostId(postId: string, params: { limit?: number; offset?: number }): RepositoryResponse<CommentPayload[]>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<CommentPayload>;
}
