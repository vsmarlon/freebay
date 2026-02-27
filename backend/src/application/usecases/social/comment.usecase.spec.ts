import { CreateCommentUseCase, GetCommentsUseCase } from './comment.usecase';
import { ICommentRepository, IPostRepository } from '@/domain/repositories';
import { CommentEntity, PostEntity } from '@/domain/entities';

const mockPost: PostEntity = {
  id: 'post-1',
  content: 'Hello world',
  type: 'REGULAR',
  userId: 'user-1',
  likesCount: 0,
  commentsCount: 3,
  sharesCount: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockComment: CommentEntity = {
  id: 'comment-1',
  content: 'Great post!',
  userId: 'user-2',
  postId: 'post-1',
  createdAt: new Date(),
};

const mockCommentRepository: jest.Mocked<ICommentRepository> = {
  findByPostId: jest.fn(),
  create: jest.fn(),
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

describe('CreateCommentUseCase', () => {
  let sut: CreateCommentUseCase;

  beforeEach(() => {
    sut = new CreateCommentUseCase(mockCommentRepository, mockPostRepository);
    jest.clearAllMocks();
  });

  it('should return left(NotFoundError) when post does not exist', async () => {
    mockPostRepository.findById.mockResolvedValue(null);

    const result = await sut.execute({
      content: 'Nice!',
      userId: 'user-2',
      postId: 'nonexistent',
    });

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
  });

  it('should create comment and increment count', async () => {
    mockPostRepository.findById.mockResolvedValue(mockPost);
    mockCommentRepository.create.mockResolvedValue(mockComment);

    const result = await sut.execute({
      content: 'Great post!',
      userId: 'user-2',
      postId: 'post-1',
    });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.content).toBe('Great post!');
    }
    expect(mockCommentRepository.create).toHaveBeenCalledWith({
      content: 'Great post!',
      userId: 'user-2',
      postId: 'post-1',
    });
    expect(mockPostRepository.incrementComments).toHaveBeenCalledWith('post-1');
  });
});

describe('GetCommentsUseCase', () => {
  let sut: GetCommentsUseCase;

  beforeEach(() => {
    sut = new GetCommentsUseCase(mockCommentRepository);
    jest.clearAllMocks();
  });

  it('should return comments list', async () => {
    mockCommentRepository.findByPostId.mockResolvedValue([mockComment]);

    const result = await sut.execute('post-1', { limit: 20 });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].content).toBe('Great post!');
    }
  });

  it('should pass cursor and limit to repository', async () => {
    mockCommentRepository.findByPostId.mockResolvedValue([]);

    await sut.execute('post-1', { cursor: 'abc', limit: 10 });

    expect(mockCommentRepository.findByPostId).toHaveBeenCalledWith('post-1', {
      cursor: 'abc',
      limit: 10,
    });
  });
});
