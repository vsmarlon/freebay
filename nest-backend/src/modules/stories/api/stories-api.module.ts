import { Module } from '@nestjs/common';
import { StoriesService } from './stories.service';
import { StoriesController } from '../stories.controller';
import { GetStoriesUseCase } from '../usecases/get-stories.usecase';
import { GetUserStoriesUseCase } from '../usecases/get-user-stories.usecase';
import { CreateStoryUseCase } from '../usecases/create-story.usecase';
import { ViewStoryUseCase } from '../usecases/view-story.usecase';
import { DeleteStoryUseCase } from '../usecases/delete-story.usecase';
import { StoryRepository } from '../domain/repositories/story.repository';
import { PrismaStoryRepository } from '../data/repositories/story-database.repository';

@Module({
  controllers: [StoriesController],
  providers: [
    StoriesService,
    { provide: StoryRepository, useClass: PrismaStoryRepository },
    GetStoriesUseCase,
    GetUserStoriesUseCase,
    CreateStoryUseCase,
    ViewStoryUseCase,
    DeleteStoryUseCase,
  ],
})
export class StoriesApiModule {}
