import { Module } from "@nestjs/common";
import { SocialReadController } from "./social-read.controller";
import { SocialWriteController } from "./social-write.controller";
import { SocialQuoteController } from './social-quote.controller';

// Repositories
import { CommentDatabaseRepository } from "./data/repositories/comment-database.repository";
import { LikeDatabaseRepository } from "./data/repositories/like-database.repository";
import { PostDatabaseRepository } from "./data/repositories/post-database.repository";
import { SavedPostDatabaseRepository } from "./data/repositories/saved-post-database.repository";
import { ShareDatabaseRepository } from "./data/repositories/share-database.repository";
import { CommentInteractionDatabaseRepository } from './data/repositories/comment-interaction-database.repository';
import { QuoteDatabaseRepository } from './data/repositories/quote-database.repository';

// Usecases
import { CreatePostUseCase } from "./usecases/create-post.usecase";
import { CommentUseCase } from "./usecases/comment.usecase";
import { LikePostUseCase } from "./usecases/like-post.usecase";
import { UnlikePostUseCase } from "./usecases/unlike-post.usecase";
import { GetPostUseCase } from "./usecases/get-post.usecase";
import { GetFeedUseCase } from "./usecases/get-feed.usecase";
import { GetUserPostsUseCase } from "./usecases/get-user-posts.usecase";
import { GetProfileTimelineUseCase } from './usecases/get-profile-timeline.usecase';
import { GetUserRepostsUseCase } from "./usecases/get-user-reposts.usecase";
import { SearchPostsUseCase } from "./usecases/search-posts.usecase";
import { GetCommentsUseCase } from "./usecases/get-comments.usecase";
import { GetLikedPostsUseCase } from "./usecases/get-liked-posts.usecase";
import { SharePostUseCase } from "./usecases/share-post.usecase";
import { UnsharePostUseCase } from "./usecases/unshare-post.usecase";
import { SavePostUseCase } from "./usecases/save-post.usecase";
import { UnsavePostUseCase } from "./usecases/unsave-post.usecase";
import { LikeCommentUseCase } from "./usecases/like-comment.usecase";
import { UnlikeCommentUseCase } from "./usecases/unlike-comment.usecase";
import { DeletePostUseCase } from "./usecases/delete-post.usecase";
import { DeleteCommentUseCase } from "./usecases/delete-comment.usecase";
import { GetSavedPostsUseCase } from "./usecases/get-saved-posts.usecase";
import { ApproveCommentUseCase } from './usecases/approve-comment.usecase';
import { GetConversationUseCase } from './usecases/get-conversation.usecase';
import { ManageCommentVisibilityUseCase } from './usecases/manage-comment-visibility.usecase';
import { ManageCommentInteractionsUseCase } from './usecases/manage-comment-interactions.usecase';
import { CreateQuoteUseCase } from './usecases/create-quote.usecase';

@Module({
  controllers: [SocialReadController, SocialWriteController, SocialQuoteController],
  providers: [
    // Repositories
    CommentDatabaseRepository,
    LikeDatabaseRepository,
    PostDatabaseRepository,
    SavedPostDatabaseRepository,
    ShareDatabaseRepository,
    CommentInteractionDatabaseRepository,
    QuoteDatabaseRepository,
    // Usecases
    CreatePostUseCase,
    CreateQuoteUseCase,
    CommentUseCase,
    LikePostUseCase,
    UnlikePostUseCase,
    GetPostUseCase,
    GetFeedUseCase,
    GetUserPostsUseCase,
    GetProfileTimelineUseCase,
    GetUserRepostsUseCase,
    SearchPostsUseCase,
    GetCommentsUseCase,
    GetConversationUseCase,
    ManageCommentVisibilityUseCase,
    ManageCommentInteractionsUseCase,
    GetLikedPostsUseCase,
    SharePostUseCase,
    UnsharePostUseCase,
    SavePostUseCase,
    UnsavePostUseCase,
    LikeCommentUseCase,
    UnlikeCommentUseCase,
    DeletePostUseCase,
    DeleteCommentUseCase,
    ApproveCommentUseCase,
    GetSavedPostsUseCase,
  ],
  exports: [
    CommentDatabaseRepository,
    LikeDatabaseRepository,
    PostDatabaseRepository,
    SavedPostDatabaseRepository,
    ShareDatabaseRepository,
    CreatePostUseCase,
    CommentUseCase,
    LikePostUseCase,
    UnlikePostUseCase,
    GetPostUseCase,
    GetFeedUseCase,
    GetUserPostsUseCase,
    GetProfileTimelineUseCase,
    GetUserRepostsUseCase,
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
    GetSavedPostsUseCase,
  ],
})
export class SocialModule {}
