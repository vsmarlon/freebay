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
import { SocialService } from './social.service';
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
import { isLeft, left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';

@ApiTags('Social')
@Controller('social')
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Get('feed')
  @ApiDoc({
    summary: 'Get social feed',
    description: 'Returns paginated feed of posts from followed users or explore',
  })
  async getFeed(@CurrentUser() user: AuthUser, @Query() query: GetFeedQueryDTO) {
    const result = await this.socialService.getFeed({
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      type: query.type ?? 'explore',
      cursor: query.cursor,
      offset: query.offset,
      contentFilter: query.contentFilter,
    });
    if (result.isLeft()) return { posts: [], hasMore: false, nextCursor: null, nextOffset: null };
    return result.value;
  }

  @Get('posts/:id')
  @ApiDoc({
    summary: 'Get post by ID',
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async getPost(@Param('id') id: string) {
    const result = await this.socialService.getPost(id);
    if (isLeft(result)) return result;
    return { post: result.value };
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
    return this.socialService.createPost({ userId: user.userId, ...body, imageUrl });
  }

  @Get('posts/user/:userId')
  @ApiDoc({
    summary: 'Get user posts',
    description: 'Returns posts and reposts for a specific user',
    params: [{ name: 'userId', description: 'User UUID' }],
  })
  async getUserPosts(@Param('userId') userId: string, @Query() query: GetUserPostsQueryDTO) {
    const result = await this.socialService.getUserPosts({
      userId,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
    if (isLeft(result)) throw result.value;
    return { posts: result.value };
  }

  @Get('posts/search')
  @ApiDoc({
    summary: 'Search posts',
  })
  async searchPosts(@CurrentUser() user: AuthUser, @Query() query: SearchPostsQueryDTO) {
    const result = await this.socialService.searchPosts({
      query: query.q || '',
      filter: query.filter || 'all',
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
    if (isLeft(result)) throw result.value;
    return { posts: result.value };
  }

  @Post('posts/:id/like')
  @Authenticated({
    summary: 'Like a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async likePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.likePost({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/like')
  @Authenticated({
    summary: 'Unlike a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unlikePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.unlikePost({ userId: user.userId, postId: id });
  }

  @Get('posts/liked')
  @Authenticated({
    summary: 'Get liked posts',
  })
  async getLikedPosts(@CurrentUser() user: AuthUser) {
    const result = await this.socialService.getLikedPosts(user.userId);
    if (isLeft(result)) throw result.value;
    return { posts: result.value };
  }

  @Post('posts/:id/share')
  @Authenticated({
    summary: 'Share/repost a post',
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.CREATED,
  })
  async sharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.sharePost({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/share')
  @Authenticated({
    summary: 'Remove share/repost',
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.OK,
  })
  async unsharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.unsharePost({ userId: user.userId, postId: id });
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
    return this.socialService.createComment({
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
    const result = await this.socialService.getComments({ postId: id, limit: 20 });
    if (isLeft(result)) throw result.value;
    return { comments: result.value };
  }

  @Post('comments/:commentId/like')
  @Authenticated({
    summary: 'Like a comment',
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async likeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    return this.socialService.likeComment({ userId: user.userId, commentId });
  }

  @Delete('comments/:commentId/like')
  @Authenticated({
    summary: 'Unlike a comment',
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async unlikeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    return this.socialService.unlikeComment({ userId: user.userId, commentId });
  }

  @Post('posts/:id/save')
  @Authenticated({
    summary: 'Save a post',
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    httpCode: HttpStatus.CREATED,
  })
  async savePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.savePost({ userId: user.userId, postId: id });
  }

  @Delete('posts/:id/save')
  @Authenticated({
    summary: 'Unsave a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unsavePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.socialService.unsavePost({ userId: user.userId, postId: id });
  }
}
