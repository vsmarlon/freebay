import { Injectable } from "@nestjs/common";
import { GetStoriesUseCase } from "./usecases/get-stories.usecase";
import { GetUserStoriesUseCase } from "./usecases/get-user-stories.usecase";
import { CreateStoryUseCase } from "./usecases/create-story.usecase";
import { ViewStoryUseCase } from "./usecases/view-story.usecase";
import { DeleteStoryUseCase } from "./usecases/delete-story.usecase";
import { CreateStoryInput } from "./dtos/stories.dto";

@Injectable()
export class StoriesService {
  constructor(
    private readonly getStoriesUseCase: GetStoriesUseCase,
    private readonly getUserStoriesUseCase: GetUserStoriesUseCase,
    private readonly createStoryUseCase: CreateStoryUseCase,
    private readonly viewStoryUseCase: ViewStoryUseCase,
    private readonly deleteStoryUseCase: DeleteStoryUseCase,
  ) {}

  async getStories(userId?: string) {
    return this.getStoriesUseCase.execute(userId);
  }

  async getUserStories(userId: string) {
    return this.getUserStoriesUseCase.execute(userId);
  }

  async createStory(input: CreateStoryInput) {
    return this.createStoryUseCase.execute(input);
  }

  async viewStory(input: { storyId: string; viewerId: string }) {
    return this.viewStoryUseCase.execute(input);
  }

  async deleteStory(input: { storyId: string; userId: string }) {
    return this.deleteStoryUseCase.execute(input);
  }
}
