import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { toDataUri } from '@/shared/utils/file.utils';
import {
  CreatePostDTO,
  CreateCommentDTO,
  GetFeedQueryDTO,
  GetUserPostsQueryDTO,
  SearchPostsQueryDTO,
} from './dtos/social.dto';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';

// Direct UseCases
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

@ApiTags('Social')
@Controller('social')
export class SocialController {
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

  @Get('feed')
  @ApiDoc({
    summary: 'Get social feed',
    description: 'Returns paginated feed of posts from followed users or explore',
  })
  async getFeed(@CurrentUser() user: AuthUser, @Query() query: GetFeedQueryDTO) {
    return this.getFeedUseCase.execute({
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      type: query.type ?? 'explore',
      cursor: query.cursor,
      offset: query.offset,
      contentFilter: query.contentFilter,
    });
  }

  @Get('posts/:id')
  @ApiDoc({
    summary: 'Get post by ID',
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async getPost(@Param('id') id: string) {
    return this.getPostUseCase.execute(id);
  }

  @Post('posts')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @Authenticated({
    summary: 'Create a post',
    description: 'Creates a new social post with optional image upload',
    bodyType: CreatePostDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  async createPost(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreatePostDTO,
  ) {
    if (file) {
      const mimeError = validateImageFile(file);
      if (mimeError) return left(new BadRequestError(mimeError));
    }
    const imageUrl = file ? toDataUri(file) : body.imageUrl;
    return this.createPostUseCase.execute({ userId: user.userId, ...body, imageUrl });
  }

  @Get('posts/user/:userId')
  @ApiDoc({
    summary: 'Get user posts',
    description: 'Returns posts and reposts for a specific user',
    params: [{ name: 'userId', description: 'User UUID' }],
  })
  async getUserPosts(@Param('userId') userId: string, @Query() query: GetUserPostsQueryDTO) {
    return this.getUserPostsUseCase.execute({
      userId,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @Get('posts/search')
  @ApiDoc({
    summary: 'Search posts',
  })
  async searchPosts(@CurrentUser() user: AuthUser, @Query() query: SearchPostsQueryDTO) {
    return this.searchPostsUseCase.execute({
      query: query.q || '',
      filter: query.filter || 'all',
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @Post('posts/:id/like')
  @Authenticated({
    summary: 'Like a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async likePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.likePostUseCase.execute({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/like')
  @Authenticated({
    summary: 'Unlike a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unlikePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.unlikePostUseCase.execute({ userId: user.userId, postId: id });
  }

  @Get('posts/liked')
  @Authenticated({
    summary: 'Get liked posts',
  })
  async getLikedPosts(@CurrentUser() user: AuthUser) {
    return this.getLikedPostsUseCase.execute(user.userId);
  }

  @Post('posts/:id/share')
  @Authenticated({
    summary: 'Share/repost a post',
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.CREATED,
  })
  async sharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.sharePostUseCase.execute({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/share')
  @Authenticated({
    summary: 'Remove share/repost',
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.OK,
  })
  async unsharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.unsharePostUseCase.execute({ userId: user.userId, postId: id });
  }

  @Post('posts/:id/comments')
  @Authenticated({
    summary: 'Create comment on post',
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    bodyType: CreateCommentDTO,
    httpCode: HttpStatus.CREATED,
  })
  async createComment(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body() body: CreateCommentDTO,
  ) {
    return this.commentUseCase.execute({
      userId: user.userId,
      postId: id,
      content: body.content,
      parentId: body.parentId,
      mentionIds: body.mentionIds,
    });
  }

  @Get('posts/:id/comments')
  @ApiDoc({
    summary: 'Get comments for a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async getComments(@Param('id') id: string) {
    return this.getCommentsUseCase.execute({ postId: id, limit: 20 });
  }

  @Post('comments/:commentId/like')
  @Authenticated({
    summary: 'Like a comment',
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async likeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    return this.likeCommentUseCase.execute({ userId: user.userId, commentId });
  }

  @Delete('comments/:commentId/like')
  @Authenticated({
    summary: 'Unlike a comment',
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async unlikeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    return this.unlikeCommentUseCase.execute({ userId: user.userId, commentId });
  }

  @Post('posts/:id/save')
  @Authenticated({
    summary: 'Save a post',
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.CREATED,
  })
  async savePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.savePostUseCase.execute({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/save')
  @Authenticated({
    summary: 'Unsave a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unsavePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.unsavePostUseCase.execute({ userId: user.userId, postId: id });
  }
}
