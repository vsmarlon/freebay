import { Test, TestingModule } from '@nestjs/testing';
import { RemoveContentUseCase } from './remove-content.usecase';
import { ModerationRepository } from '../domain/repositories/moderation.repository';
import { left, right } from '@/shared/core/either';
import { DatabaseError, NotFoundError } from '@/shared/core/errors';

const mockModerationRepository = {
  softDeleteProduct: jest.fn(),
  softDeletePost: jest.fn(),
  softDeleteComment: jest.fn(),
  recordAction: jest.fn(),
};

describe('RemoveContentUseCase', () => {
  let sut: RemoveContentUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RemoveContentUseCase,
        { provide: ModerationRepository, useValue: mockModerationRepository },
      ],
    }).compile();

    sut = module.get(RemoveContentUseCase);

    mockModerationRepository.softDeleteProduct.mockResolvedValue(right({ count: 1 }));
    mockModerationRepository.softDeletePost.mockResolvedValue(right({ count: 1 }));
    mockModerationRepository.softDeleteComment.mockResolvedValue(right({ count: 1 }));
    mockModerationRepository.recordAction.mockResolvedValue(right(undefined));
  });

  it('deve remover um produto e registrar PRODUCT_REMOVED', async () => {
    const result = await sut.execute({
      targetType: 'PRODUCT',
      targetId: 'product-1',
      adminId: 'admin-1',
      reason: 'proibido',
    });

    expect(result.isRight()).toBe(true);
    expect(mockModerationRepository.softDeleteProduct).toHaveBeenCalledWith('product-1');
    expect(mockModerationRepository.recordAction).toHaveBeenCalledWith({
      actorId: 'admin-1',
      targetType: 'PRODUCT',
      targetId: 'product-1',
      action: 'PRODUCT_REMOVED',
      reason: 'proibido',
    });
  });

  it('deve remover uma publicação e registrar POST_REMOVED', async () => {
    await sut.execute({ targetType: 'POST', targetId: 'post-1', adminId: 'admin-1' });

    expect(mockModerationRepository.softDeletePost).toHaveBeenCalledWith('post-1');
    expect(mockModerationRepository.recordAction.mock.calls[0][0].action).toBe('POST_REMOVED');
  });

  it('deve remover um comentário e registrar COMMENT_REMOVED', async () => {
    await sut.execute({ targetType: 'COMMENT', targetId: 'comment-1', adminId: 'admin-1' });

    expect(mockModerationRepository.softDeleteComment).toHaveBeenCalledWith('comment-1');
    expect(mockModerationRepository.recordAction.mock.calls[0][0].action).toBe('COMMENT_REMOVED');
  });

  it('deve retornar NotFoundError quando o conteúdo já estava removido', async () => {
    mockModerationRepository.softDeleteProduct.mockResolvedValue(right({ count: 0 }));

    const result = await sut.execute({
      targetType: 'PRODUCT',
      targetId: 'product-1',
      adminId: 'admin-1',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
    expect(mockModerationRepository.recordAction).not.toHaveBeenCalled();
  });

  it('deve propagar a falha quando a remoção falha', async () => {
    mockModerationRepository.softDeletePost.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({
      targetType: 'POST',
      targetId: 'post-1',
      adminId: 'admin-1',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
