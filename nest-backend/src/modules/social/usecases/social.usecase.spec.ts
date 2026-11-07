import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { StoryAudience } from '@prisma/client';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { CreatePostUseCase } from './create-post.usecase';
import { LikePostUseCase } from './like-post.usecase';
import { UnlikePostUseCase } from './unlike-post.usecase';
import { CommentUseCase } from './comment.usecase';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { LikeDatabaseRepository } from '../data/repositories/like-database.repository';
import { CommentDatabaseRepository } from '../data/repositories/comment-database.repository';
import {
  createCommentInput,
  createPostInput,
  expectLeft,
  expectRight,
} from './social-test-fixtures';

describe('CreatePostUseCase', () => {
  let sut: CreatePostUseCase;
  let mockPostRepository: { create: jest.Mock; createMentions: jest.Mock };
  let mockNotificationService: { notifyMention: jest.Mock };

  beforeEach(async () => {
    mockPostRepository = {
      create: jest.fn().mockImplementation((data) => Promise.resolve(right({
        id: 'post-123',
        content: data.content ?? null,
        media: (data.media?.create ?? []).map((item: Record<string, unknown>, order: number) => ({
          id: `media-${order}`,
          postId: 'post-123',
          thumbnailUrl: null,
          altText: null,
          durationMs: null,
          coverTimestampMs: null,
          hotspots: null,
          ...item,
        })),
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
    mockNotificationService = { notifyMention: jest.fn().mockResolvedValue(undefined) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePostUseCase,
        { provide: PostDatabaseRepository, useValue: mockPostRepository },
        { provide: NotificationService, useValue: mockNotificationService },
      ],
    }).compile();

    sut = module.get(CreatePostUseCase);
  });

  it('creates a regular post', async () => {
    const result = await sut.execute(createPostInput());
    const post = expectRight(result);

    expect(post.content).toBe('Test content');
    expect(post.type).toBe('REGULAR');
    expect(mockPostRepository.create).toHaveBeenCalled();
  });

  it('creates a post with image', async () => {
    const result = await sut.execute(createPostInput({
      media: [{ url: 'http://example.com/image.jpg', type: 'IMAGE', hotspots: [] }],
      type: 'PRODUCT',
    }));
    const post = expectRight(result);

    expect(post.media[0]?.url).toBe('http://example.com/image.jpg');
    expect(post.type).toBe('PRODUCT');
  });

  it('does not persist or return image hashes for close-friends posts', async () => {
    const result = await sut.execute(createPostInput({
      media: [{
        url: '/media/privatepost/123e4567-e89b-12d3-a456-426614174000.jpg',
        type: 'IMAGE',
        blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
        hotspots: [],
      }],
      audience: StoryAudience.CLOSE_FRIENDS,
    }));

    expect(mockPostRepository.create).toHaveBeenCalledWith(expect.objectContaining({
      media: { create: [expect.objectContaining({ blurHash: null })] },
      audience: StoryAudience.CLOSE_FRIENDS,
    }));
    expect(expectRight(result).media[0]).not.toHaveProperty('blurHash');
  });

  it('creates PostMention rows for each mentionId', async () => {
    const result = await sut.execute(createPostInput({
      content: 'Hey @friend!',
      mentionIds: ['friend-user-id'],
    }));

    expectRight(result);
    expect(mockPostRepository.createMentions).toHaveBeenCalledWith('post-123', ['friend-user-id']);
    expect(mockNotificationService.notifyMention).toHaveBeenCalledWith(
      'friend-user-id',
      expect.stringContaining('mencionou'),
      'post-123',
    );
  });

  it('filters out author own userId from mentionIds', async () => {
    const result = await sut.execute(createPostInput({
      content: 'Hey self!',
      mentionIds: ['user-123', 'friend-user-id'],
    }));

    expectRight(result);
    expect(mockPostRepository.createMentions).toHaveBeenCalledWith('post-123', ['friend-user-id']);
  });

  it('does not create mentions when mentionIds is empty', async () => {
    const result = await sut.execute(createPostInput({ content: 'No mentions', mentionIds: [] }));

    expectRight(result);
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
        { provide: PostDatabaseRepository, useValue: mockPostRepository },
        { provide: LikeDatabaseRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get(LikePostUseCase);
  });

  it('likes a post when it exists', async () => {
    mockPostRepository.findById.mockResolvedValue(right({ id: 'post-123', content: 'Test', likesCount: 0 }));

    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });
    const like = expectRight(result);

    expect(like).toEqual({ active: true, count: 1 });
    expect(mockLikeRepository.createLike).toHaveBeenCalled();
    expect(mockPostRepository.update).toHaveBeenCalledWith('post-123', { likesCount: { increment: 1 } });
  });

  it('returns error if post not found', async () => {
    mockPostRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });

    expect(expectLeft(result)).toBeInstanceOf(NotFoundError);
  });
});

describe('UnlikePostUseCase', () => {
  let sut: UnlikePostUseCase;
  let mockPostRepository: { update: jest.Mock };
  let mockLikeRepository: { findPostLike: jest.Mock; deletePostLikeByUser: jest.Mock };

  beforeEach(async () => {
    mockPostRepository = { update: jest.fn().mockResolvedValue(right({})) };
    mockLikeRepository = {
      findPostLike: jest.fn().mockResolvedValue(right({ id: 'like-123' })),
      deletePostLikeByUser: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UnlikePostUseCase,
        { provide: PostDatabaseRepository, useValue: mockPostRepository },
        { provide: LikeDatabaseRepository, useValue: mockLikeRepository },
      ],
    }).compile();

    sut = module.get(UnlikePostUseCase);
  });

  it('unlikes a post', async () => {
    const result = await sut.execute({ userId: 'user-123', postId: 'post-123' });
    const unlike = expectRight(result);

    expect(unlike).toEqual({ active: false, count: 0 });
    expect(mockLikeRepository.deletePostLikeByUser).toHaveBeenCalledWith('user-123', 'post-123');
    expect(mockPostRepository.update).toHaveBeenCalledWith('post-123', { likesCount: { decrement: 1 } });
  });
});

describe('CommentUseCase', () => {
  let sut: CommentUseCase;
  let mockCommentRepository: { createIdempotent: jest.Mock };
  let mockNotificationService: { deliverPersisted: jest.Mock };

  beforeEach(async () => {
    mockCommentRepository = {
      createIdempotent: jest.fn().mockResolvedValue(right({
        comment: { id: 'comment-123', content: 'Great post!', createdAt: new Date() },
        notifications: [],
        replayed: false,
      })),
    };
    mockNotificationService = { deliverPersisted: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentUseCase,
        { provide: CommentDatabaseRepository, useValue: mockCommentRepository },
        { provide: NotificationService, useValue: mockNotificationService },
        { provide: PostDatabaseRepository, useValue: { findById: jest.fn().mockResolvedValue(right({ id: 'post-123', userId: 'owner-123', audience: 'EVERYONE' })) } },
      ],
    }).compile();

    sut = module.get(CommentUseCase);
  });

  it('creates a comment', async () => {
    const result = await sut.execute(createCommentInput());
    const comment = expectRight(result);

    expect(comment.content).toBe('Great post!');
    expect(comment.postId).toBe('post-123');
    expect(comment.userId).toBe('user-123');
    expect(mockCommentRepository.createIdempotent).toHaveBeenCalledWith(
      expect.objectContaining({ content: 'Great post!' }),
      expect.objectContaining({ postId: 'post-123', userId: 'user-123', mentionIds: [] }),
    );
  });

  it('creates CommentMention rows for each mentionId', async () => {
    const result = await sut.execute(createCommentInput({
      content: '@friend nice!',
      mentionIds: ['friend-user-id'],
    }));

    expectRight(result);
    expect(mockCommentRepository.createIdempotent).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ mentionIds: ['friend-user-id'] }),
    );
  });

  it('filters out author own userId from comment mentionIds', async () => {
    const result = await sut.execute(createCommentInput({
      content: '@self hi',
      mentionIds: ['user-123', 'friend-user-id'],
    }));

    expectRight(result);
    expect(mockCommentRepository.createIdempotent).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ mentionIds: ['friend-user-id'] }),
    );
  });
});
