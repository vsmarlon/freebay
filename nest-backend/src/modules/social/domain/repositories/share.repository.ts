import { RepositoryResponse } from '@/shared/core/either';
import { PostPayload } from '../../types/social.types';

export interface ShareWithPost {
  post: PostPayload;
  user: { id: string; displayName: string; avatarUrl: string | null };
  createdAt: Date;
}

export abstract class ShareRepository {
  abstract findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null>;
  abstract create(data: Record<string, unknown>): RepositoryResponse<{ id: string }>;
  abstract delete(userId: string, postId: string): RepositoryResponse<void>;
  abstract findPostsRepostedByUser(userId: string, params: { limit?: number; cursor?: string }): RepositoryResponse<ShareWithPost[]>;
  abstract exists(userId: string, postId: string): RepositoryResponse<boolean>;
}
