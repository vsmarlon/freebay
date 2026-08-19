import { RepositoryResponse } from '@/shared/core/either';
import { ShareWithPost } from '../../types/social.types';

export abstract class ShareRepository {
  abstract findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<{ id: string }>;
  abstract delete(userId: string, postId: string): RepositoryResponse<void>;
  abstract findPostsRepostedByUser(userId: string, params: { limit?: number; cursor?: string }): RepositoryResponse<ShareWithPost[]>;
  abstract exists(userId: string, postId: string): RepositoryResponse<boolean>;
}
