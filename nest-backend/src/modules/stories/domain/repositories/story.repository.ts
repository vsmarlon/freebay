import { RepositoryResponse } from '@/shared/core/either';
import { StoryWithViews, StoryBrief, CreateStoryInput, StoryCreatePayload } from '../../types/story.types';

export abstract class StoryRepository {
  abstract findActiveWithViews(): RepositoryResponse<StoryWithViews[]>;
  abstract findByUserId(userId: string): RepositoryResponse<StoryBrief[]>;
  abstract findById(id: string): RepositoryResponse<{ id: string; userId: string; imageUrl: string } | null>;
  abstract create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload>;
  abstract delete(id: string): RepositoryResponse<void>;
  abstract upsertView(storyId: string, viewerId: string): RepositoryResponse<void>;
}
