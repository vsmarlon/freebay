import { Module } from "@nestjs/common";
import { StoriesController } from "./stories.controller";
import { StoriesService } from "./stories.service";
import { GetStoriesUseCase } from "./usecases/get-stories.usecase";
import { GetUserStoriesUseCase } from "./usecases/get-user-stories.usecase";
import { CreateStoryUseCase } from "./usecases/create-story.usecase";
import { ViewStoryUseCase } from "./usecases/view-story.usecase";
import { DeleteStoryUseCase } from "./usecases/delete-story.usecase";
import { PrismaStoryRepository } from "./data/repositories/story-database.repository";
import { StoryHighlightDatabaseRepository } from './data/repositories/story-highlight-database.repository';
import { SaveStoryHighlightUseCase } from './usecases/save-story-highlight.usecase';
import { DeleteStoryHighlightUseCase } from './usecases/delete-story-highlight.usecase';

@Module({
  controllers: [StoriesController],
  providers: [
    StoriesService,
    PrismaStoryRepository,
    StoryHighlightDatabaseRepository,
    SaveStoryHighlightUseCase,
    DeleteStoryHighlightUseCase,
    GetStoriesUseCase,
    GetUserStoriesUseCase,
    CreateStoryUseCase,
    ViewStoryUseCase,
    DeleteStoryUseCase,
  ],
  exports: [StoriesService],
})
export class StoriesModule {}
