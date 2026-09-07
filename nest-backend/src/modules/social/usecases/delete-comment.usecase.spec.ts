import { Test, TestingModule } from '@nestjs/testing';
import { DeleteCommentUseCase } from './delete-comment.usecase';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { right } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('DeleteCommentUseCase', () => {
  let useCase: DeleteCommentUseCase;
  let mockCommentRepo: { findById: jest.Mock; softDelete: jest.Mock };

  beforeEach(async () => {
    mockCommentRepo = {
      findById: jest.fn(),
      softDelete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteCommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepo },
      ],
    }).compile();

    useCase = module.get(DeleteCommentUseCase);
  });

  it('should return NotFoundError if comment not found', async () => {
    mockCommentRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return ForbiddenError if user is not author', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'other-user' }),
    );

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should soft delete comment successfully', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'user-1' }),
    );
    mockCommentRepo.softDelete.mockResolvedValue(right(undefined));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.softDelete).toHaveBeenCalledWith('c-1');
  });
});
