import { LikePostUseCase, UnlikePostUseCase } from './like.usecase';
import { ILikeRepository, IPostRepository } from '@/domain/repositories';
import { LikeEntity, PostEntity } from '@/domain/entities';

const mockPost: PostEntity = {
  id: 'post-1',
  content: 'Hello world',
  type: 'REGULAR',
  userId: 'user-1',
  likesCount: 5,
  commentsCount: 0,
  sharesCount: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockLike: LikeEntity = {
  id: 'like-1',
  userId: 'user-2',
  postId: 'post-1',
  createdAt: new Date(),
};

const mockLikeRepository: jest.Mocked<ILikeRepository> = {
  findByUserAndPost: jest.fn(),
  create: jest.fn(),
  delete: jest.fn(),
};

const mockPostRepository: jest.Mocked<IPostRepository> = {
  findById: jest.fn(),
  findByUserId: jest.fn(),
  findFeed: jest.fn(),
  create: jest.fn(),
  delete: jest.fn(),
  incrementLikes: jest.fn(),
  decrementLikes: jest.fn(),
  incrementComments: jest.fn(),
  incrementShares: jest.fn(),
};

describe('LikePostUseCase', () => {
  let sut: LikePostUseCase;

  beforeEach(() => {
    sut = new LikePostUseCase(mockLikeRepository, mockPostRepository);
    jest.clearAllMocks();
  });

  it('should return left(NotFoundError) when post does not exist', async () => {
    mockPostRepository.findById.mockResolvedValue(null);

    const result = await sut.execute('user-2', 'nonexistent');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
  });

  it('should be idempotent when already liked', async () => {
    mockPostRepository.findById.mockResolvedValue(mockPost);
    mockLikeRepository.findByUserAndPost.mockResolvedValue(mockLike);

    const result = await sut.execute('user-2', 'post-1');

    expect(result._tag).toBe('right');
    expect(mockLikeRepository.create).not.toHaveBeenCalled();
    expect(mockPostRepository.incrementLikes).not.toHaveBeenCalled();
  });

  it('should create like and increment count on new like', async () => {
    mockPostRepository.findById.mockResolvedValue(mockPost);
    mockLikeRepository.findByUserAndPost.mockResolvedValue(null);
    mockLikeRepository.create.mockResolvedValue(mockLike);

    const result = await sut.execute('user-2', 'post-1');

    expect(result._tag).toBe('right');
    expect(mockLikeRepository.create).toHaveBeenCalledWith('user-2', 'post-1');
    expect(mockPostRepository.incrementLikes).toHaveBeenCalledWith('post-1');
  });
});

describe('UnlikePostUseCase', () => {
  let sut: UnlikePostUseCase;

  beforeEach(() => {
    sut = new UnlikePostUseCase(mockLikeRepository, mockPostRepository);
    jest.clearAllMocks();
  });

  it('should be idempotent when not liked', async () => {
    mockLikeRepository.findByUserAndPost.mockResolvedValue(null);

    const result = await sut.execute('user-2', 'post-1');

    expect(result._tag).toBe('right');
    expect(mockLikeRepository.delete).not.toHaveBeenCalled();
    expect(mockPostRepository.decrementLikes).not.toHaveBeenCalled();
  });

  it('should delete like and decrement count', async () => {
    mockLikeRepository.findByUserAndPost.mockResolvedValue(mockLike);

    const result = await sut.execute('user-2', 'post-1');

    expect(result._tag).toBe('right');
    expect(mockLikeRepository.delete).toHaveBeenCalledWith('user-2', 'post-1');
    expect(mockPostRepository.decrementLikes).toHaveBeenCalledWith('post-1');
  });
});
