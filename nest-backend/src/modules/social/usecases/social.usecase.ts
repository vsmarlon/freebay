import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import {
  PrismaPostRepository,
  PrismaCommentRepository,
  PrismaLikeRepository,
  PrismaStoryRepository,
} from '../repositories/social.repository';
import {
  CreatePostInput,
  CreatePostOutput,
  LikePostInput,
  CreateCommentInput,
  CreateCommentOutput,
  CreateStoryInput,
  CreateStoryOutput,
} from '../dtos/social.dto';

export type {
  CreatePostInput,
  CreatePostOutput,
  LikePostInput,
  CreateCommentInput,
  CreateCommentOutput,
  CreateStoryInput,
  CreateStoryOutput,
};

@Injectable()
export class CreatePostUseCase {
  constructor(private postRepository: PrismaPostRepository) {}

  async execute(input: CreatePostInput): Promise<Either<AppError, CreatePostOutput>> {
    const post = await this.postRepository.create({
      content: input.content ?? null,
      imageUrl: input.imageUrl ?? null,
      type: input.type,
      user: { connect: { id: input.userId } },
    });

    return right({
      id: post.id,
      content: post.content,
      imageUrl: post.imageUrl,
      type: post.type as 'PRODUCT' | 'REGULAR',
      userId: post.userId!,
      createdAt: post.createdAt,
    });
  }
}

@Injectable()
export class LikePostUseCase {
  constructor(
    private postRepository: PrismaPostRepository,
    private likeRepository: PrismaLikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, { liked: boolean }>> {
    const post = await this.postRepository.findById(input.postId);
    if (!post) {
      return left(new NotFoundError('Post'));
    }

    const existingLike = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (existingLike) {
      return right({ liked: true });
    }

    await this.likeRepository.createLike({
      user: { connect: { id: input.userId } },
      post: { connect: { id: input.postId } },
    });
    await this.postRepository.incrementLikesCount(input.postId);
    return right({ liked: true });
  }
}

@Injectable()
export class UnlikePostUseCase {
  constructor(
    private postRepository: PrismaPostRepository,
    private likeRepository: PrismaLikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, { unliked: boolean }>> {
    const existingLike = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (!existingLike) {
      return right({ unliked: true });
    }
    await this.likeRepository.deletePostLikeByUser(input.userId, input.postId);
    await this.postRepository.decrementLikesCount(input.postId);
    return right({ unliked: true });
  }
}

@Injectable()
export class CommentUseCase {
  constructor(
    private commentRepository: PrismaCommentRepository,
    private postRepository: PrismaPostRepository,
  ) {}

  async execute(input: CreateCommentInput): Promise<Either<AppError, CreateCommentOutput>> {
    const comment = await this.commentRepository.create({
      content: input.content,
      post: { connect: { id: input.postId } },
      user: { connect: { id: input.userId } },
    });

    await this.postRepository.incrementCommentsCount(input.postId);

    return right({
      id: comment.id,
      postId: input.postId,
      userId: input.userId,
      content: input.content,
      createdAt: comment.createdAt,
    });
  }
}

@Injectable()
export class GetCommentsUseCase {
  async execute(_postId: string) {
    return [];
  }
}

@Injectable()
export class LikeCommentUseCase {
  async execute(_input: { userId: string; commentId: string }) {
    return right({ liked: true });
  }
}

@Injectable()
export class UnlikeCommentUseCase {
  async execute(_input: { userId: string; commentId: string }) {
    return right({ unliked: true });
  }
}

@Injectable()
export class CreateStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: CreateStoryInput): Promise<Either<AppError, CreateStoryOutput>> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const story = await this.storyRepository.create({
      user: { connect: { id: input.userId } },
      imageUrl: input.imageBase64,
      expiresAt,
    });

    return right({
      id: story.id,
      userId: input.userId,
      imageUrl: story.imageUrl,
      createdAt: story.createdAt,
    });
  }
}

@Injectable()
export class GetStoriesUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(userId?: string) {
    const stories = await this.storyRepository.findActiveWithViews();

    let userHasStory = false;
    if (userId) {
      userHasStory = stories.some(s => s.userId === userId);
    }

    const groupedByUser = stories.reduce<Record<string, { user: unknown; stories: unknown[] }>>((acc, story) => {
      const uid = story.userId;
      if (!acc[uid]) {
        acc[uid] = { user: story.user, stories: [] };
      }
      acc[uid].stories.push({
        id: story.id,
        imageUrl: story.imageUrl,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewsCount: story._count.views,
      });
      return acc;
    }, {} as Record<string, { user: unknown; stories: unknown[] }>);

    return { stories: Object.values(groupedByUser), userHasStory };
  }
}

@Injectable()
export class GetUserStoriesUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(userId: string) {
    const stories = await this.storyRepository.findByUserId(userId);
    return stories.filter(s => s.expiresAt > new Date()).map(story => ({
      id: story.id,
      imageUrl: story.imageUrl,
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
    }));
  }
}

@Injectable()
export class ViewStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: { storyId: string; viewerId: string }): Promise<Either<AppError, { viewed: boolean }>> {
    const story = await this.storyRepository.findById(input.storyId);
    if (!story) {
      return left(new NotFoundError('Story'));
    }

    if (input.viewerId) {
      await this.storyRepository.upsertView(input.storyId, input.viewerId);
    }

    return right({ viewed: true });
  }
}

@Injectable()
export class DeleteStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: { storyId: string; userId: string }): Promise<Either<AppError, { deleted: boolean }>> {
    const story = await this.storyRepository.findById(input.storyId);
    if (!story) {
      return left(new NotFoundError('Story'));
    }

    if (story.userId !== input.userId) {
      return left(new UnauthorizedError('You can only delete your own stories'));
    }

    await this.storyRepository.delete(input.storyId);
    return right({ deleted: true });
  }
}
