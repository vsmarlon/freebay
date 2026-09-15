import { Test, TestingModule } from '@nestjs/testing';
import { DeleteCommentUseCase } from './delete-comment.usecase';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { right } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('DeleteCommentUseCase', () => {
  let useCase: DeleteCommentUseCase;
  let mockCommentRepo: { findById: jest.Mock; softDeleteWithCount: jest.Mock };

  beforeEach(async () => {
    mockCommentRepo = {
      findById: jest.fn(),
      softDeleteWithCount: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteCommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepo },
      ],
    }).compile();

    useCase = module.get(DeleteCommentUseCase);
  });

  it('returns NotFoundError if comment not found', async () => {
    mockCommentRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns ForbiddenError if user is not author', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'other-user', postId: 'post-1' }),
    );

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('soft-deletes comment and decrements post commentsCount successfully', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'user-1', postId: 'post-1' }),
    );
    mockCommentRepo.softDeleteWithCount.mockResolvedValue(right(true));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.softDeleteWithCount).toHaveBeenCalledWith('c-1');
  });

  it('does not decrement again when the comment was already deleted', async () => {
    mockCommentRepo.findById.mockResolvedValueOnce(
      right({ id: 'c-1', userId: 'user-1', postId: 'post-1' }),
    ).mockResolvedValueOnce(right(null));
    mockCommentRepo.softDeleteWithCount.mockResolvedValue(right(true));

    await useCase.execute({ commentId: 'c-1', userId: 'user-1' });
    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockCommentRepo.softDeleteWithCount).toHaveBeenCalledTimes(1);
  });
});
