import { DeleteCommentUseCase } from './delete-comment.usecase';
import { CommentRepository } from '../domain/repositories/comment.repository';
import { right } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('DeleteCommentUseCase', () => {
  let useCase: DeleteCommentUseCase;
  let mockCommentRepo: jest.Mocked<CommentRepository>;

  beforeEach(() => {
    mockCommentRepo = {
      findById: jest.fn(),
      findAllByPostId: jest.fn(),
      create: jest.fn(),
      createMentions: jest.fn(),
      softDelete: jest.fn(),
    } as unknown as jest.Mocked<CommentRepository>;

    useCase = new DeleteCommentUseCase(mockCommentRepo);
  });

  it('should return NotFoundError if comment not found', async () => {
    mockCommentRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return ForbiddenError if user is not author', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'other-user' } as any),
    );

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should soft delete comment successfully', async () => {
    mockCommentRepo.findById.mockResolvedValue(
      right({ id: 'c-1', userId: 'user-1' } as any),
    );
    mockCommentRepo.softDelete.mockResolvedValue(right(undefined));

    const result = await useCase.execute({ commentId: 'c-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.softDelete).toHaveBeenCalledWith('c-1');
  });
});
