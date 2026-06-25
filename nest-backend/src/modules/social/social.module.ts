import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import { CreatePostUseCase } from './usecases/create-post.usecase';
import { LikePostUseCase } from './usecases/like-post.usecase';
import { UnlikePostUseCase } from './usecases/unlike-post.usecase';
import { CommentUseCase } from './usecases/comment.usecase';
import { CreateStoryUseCase } from './usecases/create-story.usecase';
import { GetStoriesUseCase } from './usecases/get-stories.usecase';
import { GetUserStoriesUseCase } from './usecases/get-user-stories.usecase';
import { ViewStoryUseCase } from './usecases/view-story.usecase';
import { DeleteStoryUseCase } from './usecases/delete-story.usecase';
import {
  PrismaPostRepository,
  PrismaLikeRepository,
  PrismaCommentRepository,
  PrismaStoryRepository,
  PrismaShareRepository,
  PrismaSavedPostRepository,
} from './repositories/social.repository';

@Module({
  controllers: [SocialController],
  providers: [
    CreatePostUseCase,
    LikePostUseCase,
    UnlikePostUseCase,
    CommentUseCase,
    CreateStoryUseCase,
    GetStoriesUseCase,
    GetUserStoriesUseCase,
    ViewStoryUseCase,
    DeleteStoryUseCase,
    PrismaPostRepository,
    PrismaLikeRepository,
    PrismaCommentRepository,
    PrismaStoryRepository,
    PrismaShareRepository,
    PrismaSavedPostRepository,
  ],
})
export class SocialModule {}
