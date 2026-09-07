import { Module } from '@nestjs/common';
import { SocialController } from './social.controller';

// Repositories
import { PrismaCommentRepository } from './data/repositories/comment-database.repository';
import { PrismaLikeRepository } from './data/repositories/like-database.repository';
import { PrismaPostRepository } from './data/repositories/post-database.repository';
import { PrismaSavedPostRepository } from './data/repositories/saved-post-database.repository';
import { PrismaShareRepository } from './data/repositories/share-database.repository';

// Usecases
import { CreatePostUseCase } from './usecases/create-post.usecase';
import { CommentUseCase } from './usecases/comment.usecase';
import { LikePostUseCase } from './usecases/like-post.usecase';
import { UnlikePostUseCase } from './usecases/unlike-post.usecase';
import { GetPostUseCase } from './usecases/get-post.usecase';
import { GetFeedUseCase } from './usecases/get-feed.usecase';
import { GetUserPostsUseCase } from './usecases/get-user-posts.usecase';
import { SearchPostsUseCase } from './usecases/search-posts.usecase';
import { GetCommentsUseCase } from './usecases/get-comments.usecase';
import { GetLikedPostsUseCase } from './usecases/get-liked-posts.usecase';
import { SharePostUseCase } from './usecases/share-post.usecase';
import { UnsharePostUseCase } from './usecases/unshare-post.usecase';
import { SavePostUseCase } from './usecases/save-post.usecase';
import { UnsavePostUseCase } from './usecases/unsave-post.usecase';
import { LikeCommentUseCase } from './usecases/like-comment.usecase';
import { UnlikeCommentUseCase } from './usecases/unlike-comment.usecase';
import { DeletePostUseCase } from './usecases/delete-post.usecase';
import { DeleteCommentUseCase } from './usecases/delete-comment.usecase';

@Module({
  controllers: [SocialController],
  providers: [
    // Repositories
    PrismaCommentRepository,
    PrismaLikeRepository,
    PrismaPostRepository,
    PrismaSavedPostRepository,
    PrismaShareRepository,
    // Usecases
    CreatePostUseCase,
    CommentUseCase,
    LikePostUseCase,
    UnlikePostUseCase,
    GetPostUseCase,
    GetFeedUseCase,
    GetUserPostsUseCase,
    SearchPostsUseCase,
    GetCommentsUseCase,
    GetLikedPostsUseCase,
    SharePostUseCase,
    UnsharePostUseCase,
    SavePostUseCase,
    UnsavePostUseCase,
    LikeCommentUseCase,
    UnlikeCommentUseCase,
    DeletePostUseCase,
    DeleteCommentUseCase,
  ],
  exports: [
    PrismaCommentRepository,
    PrismaLikeRepository,
    PrismaPostRepository,
    PrismaSavedPostRepository,
    PrismaShareRepository,
    CreatePostUseCase,
    CommentUseCase,
    LikePostUseCase,
    UnlikePostUseCase,
    GetPostUseCase,
    GetFeedUseCase,
    GetUserPostsUseCase,
    SearchPostsUseCase,
    GetCommentsUseCase,
    GetLikedPostsUseCase,
    SharePostUseCase,
    UnsharePostUseCase,
    SavePostUseCase,
    UnsavePostUseCase,
    LikeCommentUseCase,
    UnlikeCommentUseCase,
    DeletePostUseCase,
    DeleteCommentUseCase,
  ],
})
export class SocialModule {}
