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
import { CreatePostDTO, CreateStoryInput, createPostSchema, createCommentSchema } from './dtos/social.dto';
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
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaSavedPostRepository } from './repositories/social.repository';

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
  async getFeed(
    @CurrentUser() user: AuthUser,
    @Query('limit') limit?: string,
    @Query('type') type?: string,
  ) {
    const userId = user?.userId || '';
    const feedType = (type === 'following' ? 'following' : 'explore') as 'explore' | 'following';
    const posts = await this.postRepository.findFeed({
      userId,
      limit: limit ? parseInt(limit) : 20,
      type: feedType,
    });
    return { posts };
  }

  @Get('posts/:id')
  async getPost(@Param('id') id: string) {
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }
    return { post };
  }

  @Post('posts')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 1000000 },
    }),
  )
  @HttpCode(HttpStatus.CREATED)
  async createPost(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body(new ZodValidationPipe(createPostSchema)) body: CreatePostDTO,
  ) {
    const userId = user.userId;
    const imageUrl = file ? this.toDataUri(file) : body.imageUrl;
    const result = await this.createPostUseCase.execute({ userId, ...body, imageUrl });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('posts/user/:userId')
  async getUserPosts(
    @Param('userId') userId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    const posts = await this.postRepository.findByUserId(userId, {
      limit: limit ? parseInt(limit) : 20,
      cursor,
    });
    return { posts };
  }

  @Get('posts/search')
  async searchPosts(
    @CurrentUser() user: AuthUser,
    @Query('q') q?: string,
    @Query('filter') filter?: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = user?.userId || '';
    const posts = await this.postRepository.searchPosts({
      query: q || '',
      filter: (filter as 'all' | 'following' | 'followers') || 'all',
      userId,
      limit: limit ? parseInt(limit) : 20,
      cursor,
    });
    return { posts };
  }

  @Post('posts/:id/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
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
  async getLikedPosts(@CurrentUser() user: AuthUser) {
    const likes = await this.likeRepository.findLikedByUserId(user.userId);
    const posts = likes.map(like => like.post).filter(Boolean);
    return { posts };
  }

  @Post('posts/:id/share')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  async sharePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const post = await this.postRepository.findById(id);
    if (!post) {
      return left(new AppError('NOT_FOUND', 'Post não encontrado'));
    }

    const existingShare = await this.shareRepository.findByUserAndPost(user.userId, id);
    if (existingShare) {
      return { shared: true, alreadyShared: true };
    }

    await this.shareRepository.create({
      user: { connect: { id: user.userId } },
      post: { connect: { id } },
    });

    await this.postRepository.incrementSharesCount(id);

    return { shared: true, alreadyShared: false };
  }

  @Post('posts/:id/comments')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  async createComment(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(createCommentSchema)) body: { content: string; parentId?: string },
  ) {
    const userId = user.userId;
    const comment = await this.commentRepository.create({
      post: { connect: { id: id } },
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
  async getComments(@Param('id') id: string) {
    const comments = await this.commentRepository.findByPostId(id, { limit: 20 });
    return { comments };
  }

  @Post('comments/:commentId/like')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
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
  async unlikeComment(@Param('commentId') commentId: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    await this.likeRepository.deleteCommentLike({ userId_commentId: { userId, commentId } });
    return { unliked: true };
  }

  @Post('posts/:id/save')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
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
  async unsavePost(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const existing = await this.savedPostRepository.findByUserAndPost(user.userId, id);
    if (!existing) {
      return { unsaved: true };
    }
    await this.savedPostRepository.unsave(user.userId, id);
    return { unsaved: true };
  }

  @Get('stories')
  async getStories(@CurrentUser() user: AuthUser) {
    const userId = user?.userId;
    const result = await this.getStoriesUseCase.execute(userId);
    return { stories: result.stories, userHasStory: result.userHasStory };
  }

  @Get('stories/user/:userId')
  async getUserStories(@Param('userId') userId: string) {
    const stories = await this.getUserStoriesUseCase.execute(userId);
    return { stories };
  }

  @Post('stories')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 1000000 },
    }),
  )
  @HttpCode(HttpStatus.CREATED)
  async createStory(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Imagem é obrigatória');
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
  async deleteStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.deleteStoryUseCase.execute({ storyId: id, userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('stories/:id/view')
  async viewStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const viewerId = user?.userId || '';
    const result = await this.viewStoryUseCase.execute({ storyId: id, viewerId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
