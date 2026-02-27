import { CreatePostUseCase, GetFeedUseCase } from './create-post.usecase';
import { IPostRepository } from '@/domain/repositories';
import { PostEntity } from '@/domain/entities';

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

const mockPost: PostEntity = {
  id: 'post-1',
  content: 'Hello world',
  type: 'REGULAR',
  userId: 'user-1',
  likesCount: 0,
  commentsCount: 0,
  sharesCount: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
};

describe('CreatePostUseCase', () => {
  let sut: CreatePostUseCase;

  beforeEach(() => {
    sut = new CreatePostUseCase(mockPostRepository);
    jest.clearAllMocks();
  });

  it('should create a post and return right', async () => {
    mockPostRepository.create.mockResolvedValue(mockPost);

    const result = await sut.execute({
      content: 'Hello world',
      type: 'REGULAR',
      userId: 'user-1',
    });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.content).toBe('Hello world');
      expect(result.value.type).toBe('REGULAR');
    }
  });

  it('should allow null content', async () => {
    const productPost = { ...mockPost, content: null, type: 'PRODUCT' as const };
    mockPostRepository.create.mockResolvedValue(productPost);

    const result = await sut.execute({
      content: null,
      type: 'PRODUCT',
      userId: 'user-1',
    });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.content).toBeNull();
    }
  });
});

describe('GetFeedUseCase', () => {
  let sut: GetFeedUseCase;

  beforeEach(() => {
    sut = new GetFeedUseCase(mockPostRepository);
    jest.clearAllMocks();
  });

  it('should return feed posts', async () => {
    mockPostRepository.findFeed.mockResolvedValue([mockPost]);

    const result = await sut.execute({ userId: 'user-1', limit: 20 });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(1);
    }
  });

  it('should pass cursor and limit to repository', async () => {
    mockPostRepository.findFeed.mockResolvedValue([]);

    await sut.execute({ userId: 'user-1', cursor: 'abc123', limit: 10 });

    expect(mockPostRepository.findFeed).toHaveBeenCalledWith({
      userId: 'user-1',
      cursor: 'abc123',
      limit: 10,
    });
  });
});
