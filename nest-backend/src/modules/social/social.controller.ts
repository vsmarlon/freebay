import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { SocialService } from './social.service';
import {
  CreatePostDTO,
  CreateCommentDTO,
  GetFeedQueryDTO,
  GetUserPostsQueryDTO,
  SearchPostsQueryDTO,
} from './dtos/social.dto';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Social')
@Controller('social')
export class SocialController {
  constructor(
    private readonly socialService: SocialService,
  ) {}

  @Get('feed')
  @ApiDoc({
    summary: 'Get social feed',
    description: 'Returns paginated feed of posts from followed users or explore',
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'type', required: false, description: 'Feed type: "following" or "explore" (default)' },
    ],
  })
  async getFeed(
    @CurrentUser() user: AuthUser,
    @Query() query: GetFeedQueryDTO,
  ) {
    const result = await this.socialService.getFeed({
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      type: query.type ?? 'explore',
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { posts: result.value };
  }

  @Get('posts/:id')
  @ApiDoc({
    summary: 'Get post by ID',
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async getPost(@Param('id') id: string, @CurrentUser() _user?: AuthUser) {
    const result = await this.socialService.getPost(id);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { post: result.value };
  }

  @Post('posts')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create a post',
    description: 'Creates a new social post with optional image upload',
    bodyType: CreatePostDTO,
    responseStatus: 201,
    auth: true,
  })
  async createPost(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreatePostDTO,
  ) {
    if (file) {
      const mimeError = validateImageFile(file);
      if (mimeError) {
        return left(new AppError('BAD_REQUEST', mimeError));
      }
    }
    const userId = user.userId;
    const imageUrl = file ? this.socialService.toDataUri(file) : body.imageUrl;
    const result = await this.socialService.createPost({ userId, ...body, imageUrl });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('posts/user/:userId')
  @ApiDoc({
    summary: 'Get user posts',
    description: 'Returns posts and reposts for a specific user',
    params: [{ name: 'userId', description: 'User UUID' }],
    queries: [
      { name: 'cursor', required: false, description: 'Pagination cursor' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
    ],
  })
  async getUserPosts(
    @Param('userId') userId: string,
    @Query() query: GetUserPostsQueryDTO,
  ) {
    const limitNum = query.limit ?? 20;
    const result = await this.socialService.getUserPosts({
      userId,
      limit: limitNum,
      cursor: query.cursor,
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { posts: result.value };
  }

  @Get('posts/search')
  @ApiDoc({
    summary: 'Search posts',
    queries: [
      { name: 'q', required: false, description: 'Search query' },
      { name: 'filter', required: false, description: 'Filter: "all", "following", or "followers"' },
      { name: 'cursor', required: false, description: 'Pagination cursor' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
    ],
  })
  async searchPosts(
    @CurrentUser() user: AuthUser,
    @Query() query: SearchPostsQueryDTO,
  ) {
    const result = await this.socialService.searchPosts({
      query: query.q || '',
      filter: query.filter || 'all',
      userId: user?.userId || '',
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { posts: result.value };
  }

  @Post('posts/:id/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Like a post',
    auth: true,
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async likePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.likePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Delete('posts/:id/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Unlike a post',
    auth: true,
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unlikePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.unlikePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('posts/liked')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get liked posts',
    auth: true,
  })
  async getLikedPosts(@CurrentUser() user: AuthUser) {
    const result = await this.socialService.getLikedPosts(user.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { posts: result.value };
  }

  @Post('posts/:id/share')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Share/repost a post',
    auth: true,
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async sharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.sharePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Delete('posts/:id/share')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Remove share/repost',
    auth: true,
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async unsharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.unsharePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('posts/:id/comments')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create comment on post',
    auth: true,
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    bodyType: CreateCommentDTO,
  })
  async createComment(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body() body: CreateCommentDTO,
  ) {
    const result = await this.socialService.createComment({
      userId: user.userId,
      postId: id,
      content: body.content,
      parentId: body.parentId,
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('posts/:id/comments')
  @ApiDoc({
    summary: 'Get comments for a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async getComments(@Param('id') id: string) {
    const result = await this.socialService.getComments({ postId: id, limit: 20 });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { comments: result.value };
  }

  @Post('comments/:commentId/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Like a comment',
    auth: true,
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async likeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.likeComment({ userId: user.userId, commentId });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Delete('comments/:commentId/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Unlike a comment',
    auth: true,
    params: [{ name: 'commentId', description: 'Comment UUID' }],
  })
  async unlikeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.unlikeComment({ userId: user.userId, commentId });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('posts/:id/save')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Save a post',
    auth: true,
    responseStatus: 201,
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async savePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.savePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Delete('posts/:id/save')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Unsave a post',
    auth: true,
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async unsavePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.socialService.unsavePost({ userId: user.userId, postId: id });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

}
