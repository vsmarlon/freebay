import { Injectable } from '@nestjs/common';
import { AppError } from '@/shared/core/errors';
import { Either } from '@/shared/core/either';
import { CreatePostUseCase } from './usecases/create-post.usecase';
import { CommentUseCase } from './usecases/comment.usecase';
import { LikePostUseCase } from './usecases/like-post.usecase';
import { UnlikePostUseCase } from './usecases/unlike-post.usecase';
import { LikeCommentUseCase } from './usecases/like-comment.usecase';
import { UnlikeCommentUseCase } from './usecases/unlike-comment.usecase';
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
import { FeedQuery, UserPostsQuery, SearchPostsQuery } from './types/social.types';
import { CreatePostInput, CreatePostOutput, CreateCommentInput, CreateCommentOutput } from './dtos/social.dto';

@Injectable()
export class SocialService {
  constructor(
    private readonly createPostUseCase: CreatePostUseCase,
    private readonly commentUseCase: CommentUseCase,
    private readonly likePostUseCase: LikePostUseCase,
    private readonly unlikePostUseCase: UnlikePostUseCase,
    private readonly getPostUseCase: GetPostUseCase,
    private readonly getFeedUseCase: GetFeedUseCase,
    private readonly getUserPostsUseCase: GetUserPostsUseCase,
    private readonly searchPostsUseCase: SearchPostsUseCase,
    private readonly getCommentsUseCase: GetCommentsUseCase,
    private readonly getLikedPostsUseCase: GetLikedPostsUseCase,
    private readonly sharePostUseCase: SharePostUseCase,
    private readonly unsharePostUseCase: UnsharePostUseCase,
    private readonly savePostUseCase: SavePostUseCase,
    private readonly unsavePostUseCase: UnsavePostUseCase,
    private readonly likeCommentUseCase: LikeCommentUseCase,
    private readonly unlikeCommentUseCase: UnlikeCommentUseCase,
  ) {}

  async getFeed(query: FeedQuery) {
    return this.getFeedUseCase.execute(query);
  }

  async getPost(id: string) {
    return this.getPostUseCase.execute(id);
  }

  async getUserPosts(query: UserPostsQuery) {
    return this.getUserPostsUseCase.execute(query);
  }

  async searchPosts(query: SearchPostsQuery) {
    return this.searchPostsUseCase.execute(query);
  }

  async createPost(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    return this.createPostUseCase.execute(input);
  }

  async createComment(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    return this.commentUseCase.execute(input);
  }

  async getComments(input: { postId: string; limit?: number; offset?: number }) {
    return this.getCommentsUseCase.execute(input);
  }

  async likePost(input: { userId: string; postId: string }) {
    return this.likePostUseCase.execute(input);
  }

  async unlikePost(input: { userId: string; postId: string }) {
    return this.unlikePostUseCase.execute(input);
  }

  async getLikedPosts(userId: string) {
    return this.getLikedPostsUseCase.execute(userId);
  }

  async sharePost(input: { userId: string; postId: string }) {
    return this.sharePostUseCase.execute(input);
  }

  async unsharePost(input: { userId: string; postId: string }) {
    return this.unsharePostUseCase.execute(input);
  }

  async savePost(input: { userId: string; postId: string }) {
    return this.savePostUseCase.execute(input);
  }

  async unsavePost(input: { userId: string; postId: string }) {
    return this.unsavePostUseCase.execute(input);
  }

  async likeComment(input: { userId: string; commentId: string }) {
    return this.likeCommentUseCase.execute(input);
  }

  async unlikeComment(input: { userId: string; commentId: string }) {
    return this.unlikeCommentUseCase.execute(input);
  }
}
