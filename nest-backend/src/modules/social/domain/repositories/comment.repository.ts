import { RepositoryResponse } from '@/shared/core/either';
import { CommentFlatPayload, CommentPayload } from '../../types/social.types';

export abstract class CommentRepository {
  abstract findById(id: string): RepositoryResponse<CommentPayload | null>;
  abstract findAllByPostId(postId: string): RepositoryResponse<CommentFlatPayload[]>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<CommentPayload>;
  abstract createMentions(commentId: string, mentionedUserIds: string[]): RepositoryResponse<void>;
  abstract softDelete(id: string): RepositoryResponse<void>;
}
