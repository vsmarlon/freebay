import { RepositoryResponse } from '@/shared/core/either';

export abstract class SavedPostRepository {
  abstract findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null>;
  abstract save(userId: string, postId: string): RepositoryResponse<{ id: string }>;
  abstract unsave(userId: string, postId: string): RepositoryResponse<void>;
}
