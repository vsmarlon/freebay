import { StoryEntity } from '@/domain/entities';

export interface IStoryRepository {
  createStory(userId: string, imageUrl: string): Promise<StoryEntity>;
  getStories(userId: string): Promise<{ stories: StoryEntity[]; userHasStory: boolean }>;
  getUserStories(userId: string, viewerId: string): Promise<StoryEntity[]>;
  deleteStory(storyId: string, userId: string): Promise<void>;
  viewStory(storyId: string, viewerId: string): Promise<void>;
}
