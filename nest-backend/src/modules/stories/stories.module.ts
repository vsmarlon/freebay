import { Module } from '@nestjs/common';
import { StoriesController } from './stories.controller';
import { StoriesService } from './stories.service';
import { GetStoriesUseCase } from './usecases/get-stories.usecase';
import { GetUserStoriesUseCase } from './usecases/get-user-stories.usecase';
import { CreateStoryUseCase } from './usecases/create-story.usecase';
import { ViewStoryUseCase } from './usecases/view-story.usecase';
import { DeleteStoryUseCase } from './usecases/delete-story.usecase';
import { PrismaStoryRepository } from './data/repositories/story-database.repository';

@Module({
  controllers: [StoriesController],
  providers: [
    StoriesService,
    PrismaStoryRepository,
    GetStoriesUseCase,
    GetUserStoriesUseCase,
    CreateStoryUseCase,
    ViewStoryUseCase,
    DeleteStoryUseCase,
  ],
  exports: [StoriesService],
})
export class StoriesModule {}
