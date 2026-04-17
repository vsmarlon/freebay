import { Test, TestingModule } from '@nestjs/testing';
import { CreatePostUseCase, LikePostUseCase, UnlikePostUseCase, CommentUseCase, CreateStoryUseCase } from './social.usecase';
import { NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository, PrismaStoryRepository } from '../repositories/social.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

describe('CreatePostUseCase', () => {
  let sut: CreatePostUseCase;
  let mockPostRepository: any;

  beforeEach(async () => {
    mockPostRepository = {
      create: jest.fn().mockImplementation((data) => Promise.resolve({
        id: 'post-123',
        content: data.content ?? null,
        imageUrl: data.imageUrl ?? null,
        type: data.type,
        userId: data.user?.connect?.id ?? 'user-123',
        createdAt: new Date(),
      })),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePostUseCase,
        { provide: PrismaPostRepository, useValue: mockPostRepository },
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
  let mockPostRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockPostRepository = {
      findById: jest.fn(),
    };

    mockPrisma = {
      like: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({}),
      },
      post: {
        update: jest.fn().mockResolvedValue({}),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LikePostUseCase,
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<LikePostUseCase>(LikePostUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should like a post when it exists', async () => {
    mockPostRepository.findById.mockResolvedValue({
      id: 'post-123',
      content: 'Test',
    });

    const input = {
      userId: 'user-123',
      postId: 'post-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.liked).toBe(true);
    }
  });

  it('should return error if post not found', async () => {
    mockPostRepository.findById.mockResolvedValue(null);

    const input = {
      userId: 'user-123',
      postId: 'post-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });
});

describe('UnlikePostUseCase', () => {
  let sut: UnlikePostUseCase;
  let mockPostRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockPostRepository = {
      findById: jest.fn(),
    };

    mockPrisma = {
      like: {
        findFirst: jest.fn().mockResolvedValue({ id: 'like-123' }),
        delete: jest.fn().mockResolvedValue({}),
      },
      post: {
        update: jest.fn().mockResolvedValue({}),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UnlikePostUseCase,
        { provide: PrismaPostRepository, useValue: mockPostRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<UnlikePostUseCase>(UnlikePostUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should unlike a post', async () => {
    const input = {
      userId: 'user-123',
      postId: 'post-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.unliked).toBe(true);
    }
  });
});

describe('CommentUseCase', () => {
  let sut: CommentUseCase;
  let mockPrisma: any;

  beforeEach(async () => {
    mockPrisma = {
      comment: {
        create: jest.fn().mockResolvedValue({
          id: 'comment-123',
          content: 'Test comment',
          postId: 'post-123',
          userId: 'user-123',
        }),
      },
      post: {
        update: jest.fn().mockResolvedValue({}),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentUseCase,
        { provide: PrismaService, useValue: mockPrisma },
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
  });
});

describe('CreateStoryUseCase', () => {
  let sut: CreateStoryUseCase;
  let mockStoryRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockStoryRepository = {
      create: jest.fn().mockResolvedValue({
        id: 'story-123',
        userId: 'user-123',
        imageUrl: 'http://example.com/image.jpg',
        expiresAt: new Date(),
        createdAt: new Date(),
      }),
    };

    mockPrisma = {
      story: {
        create: jest.fn().mockResolvedValue({
          id: 'story-123',
          userId: 'user-123',
          imageUrl: 'http://example.com/image.jpg',
          expiresAt: new Date(),
          createdAt: new Date(),
        }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateStoryUseCase,
        { provide: PrismaStoryRepository, useValue: mockStoryRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<CreateStoryUseCase>(CreateStoryUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a story', async () => {
    const input = {
      userId: 'user-123',
      imageBase64: 'base64encodedimage',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });
});
