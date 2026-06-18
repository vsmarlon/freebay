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
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import {
  CreatePostUseCase,
  LikePostUseCase,
  UnlikePostUseCase,
  CreateStoryUseCase,
  GetStoriesUseCase,
  GetUserStoriesUseCase,
  ViewStoryUseCase,
  DeleteStoryUseCase,
} from './usecases/social.usecase';
import {
  CreatePostDTO,
  CreateCommentDTO,
  CreateStoryInput,
  GetFeedQueryDTO,
  GetUserPostsQueryDTO,
  SearchPostsQueryDTO,
} from './dtos/social.dto';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import {
  PrismaPostRepository,
  PrismaLikeRepository,
  PrismaStoryRepository,
  PrismaCommentRepository,
  PrismaShareRepository,
} from './repositories/social.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaSavedPostRepository } from './repositories/social.repository';

@ApiTags('Social')
@Controller('social')
export class SocialController {
  constructor(
    private readonly createPostUseCase: CreatePostUseCase,
    private readonly createStoryUseCase: CreateStoryUseCase,
    private readonly likePostUseCase: LikePostUseCase,
    private readonly unlikePostUseCase: UnlikePostUseCase,
    private readonly getStoriesUseCase: GetStoriesUseCase,
    private readonly getUserStoriesUseCase: GetUserStoriesUseCase,
    private readonly viewStoryUseCase: ViewStoryUseCase,
    private readonly deleteStoryUseCase: DeleteStoryUseCase,
    private readonly postRepository: PrismaPostRepository,
    private readonly likeRepository: PrismaLikeRepository,
    private readonly storyRepository: PrismaStoryRepository,
    private readonly commentRepository: PrismaCommentRepository,
    private readonly shareRepository: PrismaShareRepository,
    private readonly savedPostRepository: PrismaSavedPostRepository,
    private readonly prisma: PrismaService,
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
    const currentUserId = user?.userId || '';
    const posts = await this.postRepository.findFeed({
      userId: currentUserId,
      limit: query.limit ?? 20,
      type: query.type ?? 'explore',
    });

    let hasRepostedMap: Record<string, boolean> = {};
    if (currentUserId) {
      const postIds = posts.map(p => p.id);
      for (const postId of postIds) {
        hasRepostedMap[postId] = await this.shareRepository.exists(currentUserId, postId);
      }
    }

    const postsWithReposted = posts.map(post => ({
      ...post,
      hasReposted: hasRepostedMap[post.id] || false,
    }));

    return { posts: postsWithReposted };
  }

  @Get('posts/:id')
  @ApiDoc({
    summary: 'Get post by ID',
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found' }],
  })
  async getPost(@Param('id') id: string, @CurrentUser() user?: AuthUser) {
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }
    const currentUserId = user?.userId;
    let hasReposted = false;
    if (currentUserId) {
      hasReposted = await this.shareRepository.exists(currentUserId, id);
    }
    return { post: { ...post, hasReposted } };
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
    const imageUrl = file ? this.toDataUri(file) : body.imageUrl;
    const result = await this.createPostUseCase.execute({ userId, ...body, imageUrl });

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
    @CurrentUser() user?: AuthUser,
  ) {
    const limitNum = query.limit ?? 20;

    const [ownPosts, repostedPosts] = await Promise.all([
      this.postRepository.findByUserId(userId, { limit: limitNum, cursor: query.cursor }),
      this.shareRepository.findPostsRepostedByUser(userId, { limit: limitNum, cursor: query.cursor }),
    ]);

    const mergedPosts = [
      ...ownPosts.map(post => ({
        ...post,
        repostedAt: null as Date | null,
        repostedBy: null,
        isReposted: false,
      })),
      ...repostedPosts.map(share => ({
        ...share.post,
        sharesCount: share.post.sharesCount,
        repostedAt: share.createdAt,
        repostedBy: {
          id: userId,
          displayName: '',
          avatarUrl: null,
        },
        isReposted: true,
      })),
    ];

    mergedPosts.sort((a, b) => {
      const aDate = a.repostedAt ?? a.createdAt;
      const bDate = b.repostedAt ?? b.createdAt;
      return bDate.getTime() - aDate.getTime();
    });

    const posts = mergedPosts.slice(0, limitNum);

    return { posts };
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
    const currentUserId = user?.userId || '';
    const posts = await this.postRepository.searchPosts({
      query: query.q || '',
      filter: query.filter || 'all',
      userId: currentUserId,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });

    let hasRepostedMap: Record<string, boolean> = {};
    if (currentUserId) {
      const postIds = posts.map(p => p.id);
      for (const postId of postIds) {
        hasRepostedMap[postId] = await this.shareRepository.exists(currentUserId, postId);
      }
    }

    const postsWithReposted = posts.map(post => ({
      ...post,
      hasReposted: hasRepostedMap[post.id] || false,
    }));

    return { posts: postsWithReposted };
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
    const userId = user.userId;
    const result = await this.likePostUseCase.execute({ userId, postId: id });

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
    const userId = user.userId;
    const result = await this.unlikePostUseCase.execute({ userId, postId: id });

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
    const likes = await this.likeRepository.findLikedByUserId(user.userId);
    const posts = likes.map(like => like.post).filter(Boolean);
    return { posts };
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
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }

    const existingShare = await this.shareRepository.findByUserAndPost(user.userId, id);
    if (existingShare) {
      return { shared: true, alreadyShared: true, sharesCount: post.sharesCount };
    }

    await this.shareRepository.create({
      user: { connect: { id: user.userId } },
      post: { connect: { id } },
    });

    await this.postRepository.incrementSharesCount(id);
    const updatedPost = await this.postRepository.findById(id);

    return { shared: true, alreadyShared: false, sharesCount: updatedPost?.sharesCount ?? post.sharesCount + 1 };
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
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }

    const existingShare = await this.shareRepository.findByUserAndPost(user.userId, id);
    if (!existingShare) {
      return { unshared: true, sharesCount: post.sharesCount };
    }

    await this.shareRepository.delete(user.userId, id);
    await this.postRepository.decrementSharesCount(id);
    const updatedPost = await this.postRepository.findById(id);

    return { unshared: true, sharesCount: updatedPost?.sharesCount ?? post.sharesCount - 1 };
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
    const userId = user.userId;
    const comment = await this.commentRepository.create({
      post: { connect: { id } },
      user: { connect: { id: userId } },
      content: body.content,
      ...(body.parentId ? { parent: { connect: { id: body.parentId } } } : {}),
    });
    await this.prisma.post.update({
      where: { id },
      data: { commentsCount: { increment: 1 } },
    });
    return { id: comment.id, postId: id, userId, content: body.content, parentId: body.parentId ?? null, createdAt: comment.createdAt };
  }

  @Get('posts/:id/comments')
  @ApiDoc({
    summary: 'Get comments for a post',
    params: [{ name: 'id', description: 'Post UUID' }],
  })
  async getComments(@Param('id') id: string) {
    const comments = await this.commentRepository.findByPostId(id, { limit: 20 });
    return { comments };
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
    const userId = user.userId;
    await this.likeRepository.createCommentLike({
      user: { connect: { id: userId } },
      comment: { connect: { id: commentId } },
    });
    return { liked: true };
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
    const userId = user.userId;
    await this.likeRepository.deleteCommentLike({ userId_commentId: { userId, commentId } });
    return { unliked: true };
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
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }
    const existing = await this.savedPostRepository.findByUserAndPost(user.userId, id);
    if (existing) {
      return { saved: true, alreadySaved: true };
    }
    await this.savedPostRepository.save(user.userId, id);
    return { saved: true, alreadySaved: false };
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
    const existing = await this.savedPostRepository.findByUserAndPost(user.userId, id);
    if (!existing) {
      return { unsaved: true };
    }
    await this.savedPostRepository.unsave(user.userId, id);
    return { unsaved: true };
  }

  @Get('stories')
  @ApiDoc({
    summary: 'Get stories feed',
    description: 'Returns active stories from followed users',
  })
  async getStories(@CurrentUser() user: AuthUser) {
    const userId = user?.userId;
    const result = await this.getStoriesUseCase.execute(userId);
    return { stories: result.stories, userHasStory: result.userHasStory };
  }

  @Get('stories/user/:userId')
  @ApiDoc({
    summary: 'Get user stories',
    params: [{ name: 'userId', description: 'User UUID' }],
  })
  async getUserStories(@Param('userId') userId: string) {
    const stories = await this.getUserStoriesUseCase.execute(userId);
    return { stories };
  }

  @Post('stories')
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
    summary: 'Create a story',
    description: 'Uploads an image that will be available for 24h',
    auth: true,
    responseStatus: 201,
  })
  async createStory(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Imagem é obrigatória');
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      throw new BadRequestException(mimeError);
    }

    const userId = user.userId;
    const input: CreateStoryInput = {
      userId,
      imageBase64: this.toDataUri(file),
    };
    const result = await this.createStoryUseCase.execute(input);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  private toDataUri(file: Express.Multer.File): string {
    return `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
  }

  @Delete('stories/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Delete a story',
    auth: true,
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async deleteStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.deleteStoryUseCase.execute({ storyId: id, userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('stories/:id/view')
  @ApiDoc({
    summary: 'View a story',
    description: 'Marks a story as viewed by the current user',
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async viewStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const viewerId = user?.userId || '';
    const result = await this.viewStoryUseCase.execute({ storyId: id, viewerId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
