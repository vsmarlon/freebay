import { Test, TestingModule } from '@nestjs/testing';
import { DeletePostUseCase } from './delete-post.usecase';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { right } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('DeletePostUseCase', () => {
  let useCase: DeletePostUseCase;
  let mockPostRepo: { findById: jest.Mock; softDelete: jest.Mock };

  beforeEach(async () => {
    mockPostRepo = {
      findById: jest.fn(),
      softDelete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeletePostUseCase,
        { provide: PrismaPostRepository, useValue: mockPostRepo },
      ],
    }).compile();

    useCase = module.get(DeletePostUseCase);
  });

  it('returns NotFoundError if post is not found', async () => {
    mockPostRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns ForbiddenError if user is not author', async () => {
    mockPostRepo.findById.mockResolvedValue(
      right({ id: 'post-1', userId: 'other-user' }),
    );

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('soft-deletes post successfully', async () => {
    mockPostRepo.findById.mockResolvedValue(
      right({ id: 'post-1', userId: 'user-1' }),
    );
    mockPostRepo.softDelete.mockResolvedValue(right(undefined));

    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockPostRepo.softDelete).toHaveBeenCalledWith('post-1');
  });
});
