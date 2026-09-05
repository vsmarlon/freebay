import { DeletePostUseCase } from './delete-post.usecase';
import { PostRepository } from '../domain/repositories/post.repository';
import { right } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('DeletePostUseCase', () => {
  let useCase: DeletePostUseCase;
  let mockPostRepo: jest.Mocked<PostRepository>;

  beforeEach(() => {
    mockPostRepo = {
      findById: jest.fn(),
      findFeed: jest.fn(),
      findByUserId: jest.fn(),
      searchPosts: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      createMentions: jest.fn(),
      softDelete: jest.fn(),
    } as unknown as jest.Mocked<PostRepository>;

    useCase = new DeletePostUseCase(mockPostRepo);
  });

  it('should return NotFoundError if post is not found', async () => {
    mockPostRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return ForbiddenError if user is not author', async () => {
    mockPostRepo.findById.mockResolvedValue(
      right({ id: 'post-1', userId: 'other-user' } as any),
    );

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should soft delete post successfully', async () => {
    mockPostRepo.findById.mockResolvedValue(
      right({ id: 'post-1', userId: 'user-1' } as any),
    );
    mockPostRepo.softDelete.mockResolvedValue(right(undefined));

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockPostRepo.softDelete).toHaveBeenCalledWith('post-1');
  });
});
