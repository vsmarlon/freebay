import { Test, TestingModule } from '@nestjs/testing';
import { CreatePostUseCase } from './create-post.usecase';
import { LikePostUseCase } from './like-post.usecase';
import { UnlikePostUseCase } from './unlike-post.usecase';
import { CommentUseCase } from './comment.usecase';
import { NotFoundError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaLikeRepository } from '../data/repositories/like-database.repository';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';

describe('CreatePostUseCase', () => {
  let sut: CreatePostUseCase;
  let mockPostRepository: { create: jest.Mock; createMentions: jest.Mock };
  let mockNotificationService: { notifyMention: jest.Mock };

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
      createMentions: jest.fn().mockResolvedValue(right(undefined)),
    };

    mockNotificationService = {
      notifyMention: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePostUseCase,
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: NotificationService, useValue: mockNotificationService },
      ],
    }).compile();

    sut = module.get(CreatePostUseCase);
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

  it('should create PostMention rows for each mentionId', async () => {
    const input = {
      userId: 'user-123',
      content: 'Hey @friend!',
      type: 'REGULAR' as const,
      mentionIds: ['friend-user-id'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockPostRepository.createMentions).toHaveBeenCalledWith('post-123', ['friend-user-id']);
    expect(mockNotificationService.notifyMention).toHaveBeenCalledWith(
      'friend-user-id',
      expect.stringContaining('mencionou'),
      'post-123',
    );
  });

  it('should filter out author own userId from mentionIds', async () => {
    const input = {
      userId: 'user-123',
      content: 'Hey self!',
      type: 'REGULAR' as const,
      mentionIds: ['user-123', 'friend-user-id'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockPostRepository.createMentions).toHaveBeenCalledWith('post-123', ['friend-user-id']);
  });

  it('should not create mentions when mentionIds is empty', async () => {
    const input = {
      userId: 'user-123',
      content: 'No mentions',
      type: 'REGULAR' as const,
      mentionIds: [],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockPostRepository.createMentions).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyMention).not.toHaveBeenCalled();
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
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: PrismaLikeRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get(LikePostUseCase);
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
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: PrismaLikeRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get(UnlikePostUseCase);
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
  let mockCommentRepository: { create: jest.Mock; createMentions: jest.Mock };
  let mockPostRepository: { update: jest.Mock };
  let mockNotificationService: { notifyMention: jest.Mock };

  beforeEach(async () => {
    mockCommentRepository = {
      create: jest.fn().mockResolvedValue(right({
        id: 'comment-123',
        content: 'Test comment',
        postId: 'post-123',
        userId: 'user-123',
        createdAt: new Date(),
      })),
      createMentions: jest.fn().mockResolvedValue(right(undefined)),
    };

    mockPostRepository = {
      update: jest.fn().mockResolvedValue(right({})),
    };

    mockNotificationService = {
      notifyMention: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepository },
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: NotificationService, useValue: mockNotificationService },
      ],
    }).compile();

    sut = module.get(CommentUseCase);
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

  it('should create CommentMention rows for each mentionId', async () => {
    const input = {
      userId: 'user-123',
      postId: 'post-123',
      content: '@friend nice!',
      mentionIds: ['friend-user-id'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepository.createMentions).toHaveBeenCalledWith('comment-123', ['friend-user-id']);
    expect(mockNotificationService.notifyMention).toHaveBeenCalledWith(
      'friend-user-id',
      expect.stringContaining('comentário'),
      'comment-123',
    );
  });

  it('should filter out author own userId from comment mentionIds', async () => {
    const input = {
      userId: 'user-123',
      postId: 'post-123',
      content: '@self hi',
      mentionIds: ['user-123', 'friend-user-id'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepository.createMentions).toHaveBeenCalledWith('comment-123', ['friend-user-id']);
  });
});
