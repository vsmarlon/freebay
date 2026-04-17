import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';
import {
  CreatePostUseCase,
  LikePostUseCase,
  UnlikePostUseCase,
  CommentUseCase,
  GetCommentsUseCase,
  LikeCommentUseCase,
  UnlikeCommentUseCase,
  CreateStoryUseCase,
  GetStoriesUseCase,
  GetUserStoriesUseCase,
  ViewStoryUseCase,
  DeleteStoryUseCase,
} from './usecases/social.usecase';
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
    GetCommentsUseCase,
    LikeCommentUseCase,
    UnlikeCommentUseCase,
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
