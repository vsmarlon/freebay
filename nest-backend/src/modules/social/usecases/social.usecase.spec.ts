import { Test, TestingModule } from '@nestjs/testing';
import { CreatePostUseCase } from './create-post.usecase';
import { LikePostUseCase } from './like-post.usecase';
import { UnlikePostUseCase } from './unlike-post.usecase';
import { CommentUseCase } from './comment.usecase';
import { NotFoundError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { PostRepository } from '../domain/repositories/post.repository';
import { LikeRepository } from '../domain/repositories/like.repository';
import { CommentRepository } from '../domain/repositories/comment.repository';

describe('CreatePostUseCase', () => {
  let sut: CreatePostUseCase;
  let mockPostRepository: { create: jest.Mock };

  beforeEach(async () => {
    mockPostRepository = {
      create: jest.fn().mockImplementation((data) => Promise.resolve(right({
        id: 'post-123',
        content: data.content ?? null,
        imageUrl: data.imageUrl ?? null,
        type: data.type,
        userId: data.user?.connect?.id ?? 'user-123',
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        createdAt: new Date(),
        user: {
          id: data.user?.connect?.id ?? 'user-123',
          displayName: 'Test User',
          avatarUrl: null,
          isVerified: false,
        },
      }))),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePostUseCase,
        { provide: PostRepository, useValue: mockPostRepository },
      ],
    }).compile();

    sut = module.get<CreatePostUseCase>(CreatePostUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a regular post', async () => {
    const input = {
      userId: 'user-123',
      content: 'Test content',
      type: 'REGULAR' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.content).toBe('Test content');
      expect(result.value.type).toBe('REGULAR');
    }
    expect(mockPostRepository.create).toHaveBeenCalled();
  });

  it('should create a post with image', async () => {
    const input = {
      userId: 'user-123',
      imageUrl: 'http://example.com/image.jpg',
      type: 'PRODUCT' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.imageUrl).toBe('http://example.com/image.jpg');
      expect(result.value.type).toBe('PRODUCT');
    }
  });
});

describe('LikePostUseCase', () => {
  let sut: LikePostUseCase;
  let mockPostRepository: { findById: jest.Mock; update: jest.Mock };
  let mockLikeRepository: { findPostLike: jest.Mock; createLike: jest.Mock };

  beforeEach(async () => {
    mockPostRepository = {
      findById: jest.fn(),
      update: jest.fn().mockResolvedValue(right({})),
    };

    mockLikeRepository = {
      findPostLike: jest.fn().mockResolvedValue(right(null)),
      createLike: jest.fn().mockResolvedValue(right({})),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LikePostUseCase,
        { provide: PostRepository, useValue: mockPostRepository },
        { provide: LikeRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get<LikePostUseCase>(LikePostUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should like a post when it exists', async () => {
    mockPostRepository.findById.mockResolvedValue(right({
      id: 'post-123',
      content: 'Test',
    }));

    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
    expect(mockLikeRepository.createLike).toHaveBeenCalled();
    expect(mockPostRepository.update).toHaveBeenCalledWith('post-123', { likesCount: { increment: 1 } });
  });

  it('should return error if post not found', async () => {
    mockPostRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });
});

describe('UnlikePostUseCase', () => {
  let sut: UnlikePostUseCase;
  let mockPostRepository: { update: jest.Mock };
  let mockLikeRepository: { findPostLike: jest.Mock; deletePostLikeByUser: jest.Mock };

  beforeEach(async () => {
    mockPostRepository = {
      update: jest.fn().mockResolvedValue(right({})),
    };

    mockLikeRepository = {
      findPostLike: jest.fn().mockResolvedValue(right({ id: 'like-123' })),
      deletePostLikeByUser: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UnlikePostUseCase,
        { provide: PostRepository, useValue: mockPostRepository },
        { provide: LikeRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get<UnlikePostUseCase>(UnlikePostUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should unlike a post', async () => {
    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
    expect(mockLikeRepository.deletePostLikeByUser).toHaveBeenCalledWith('user-123', 'post-123');
    expect(mockPostRepository.update).toHaveBeenCalledWith('post-123', { likesCount: { decrement: 1 } });
  });
});

describe('CommentUseCase', () => {
  let sut: CommentUseCase;
  let mockCommentRepository: { create: jest.Mock };
  let mockPostRepository: { update: jest.Mock };

  beforeEach(async () => {
    mockCommentRepository = {
      create: jest.fn().mockResolvedValue(right({
        id: 'comment-123',
        content: 'Test comment',
        postId: 'post-123',
        userId: 'user-123',
        createdAt: new Date(),
      })),
    };

    mockPostRepository = {
      update: jest.fn().mockResolvedValue(right({})),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentUseCase,
        { provide: CommentRepository, useValue: mockCommentRepository },
        { provide: PostRepository, useValue: mockPostRepository },
      ],
    }).compile();

    sut = module.get<CommentUseCase>(CommentUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a comment', async () => {
    const input = {
      userId: 'user-123',
      postId: 'post-123',
      content: 'Great post!',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.content).toBe('Great post!');
      expect(result.value.postId).toBe('post-123');
      expect(result.value.userId).toBe('user-123');
    }
    expect(mockPostRepository.update).toHaveBeenCalledWith('post-123', { commentsCount: { increment: 1 } });
  });
});
