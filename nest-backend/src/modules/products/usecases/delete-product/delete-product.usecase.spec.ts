import { Test, TestingModule } from '@nestjs/testing';
import { DeleteProductUseCase } from './delete-product.usecase';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { right, left } from '@/shared/core/either';
import { NotFoundError, ForbiddenError, DatabaseError } from '@/shared/core/errors';

describe('DeleteProductUseCase', () => {
  let useCase: DeleteProductUseCase;
  let mockProductRepo: {
    findById: jest.Mock;
    delete: jest.Mock;
  };

  beforeEach(async () => {
    mockProductRepo = {
      findById: jest.fn(),
      delete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteProductUseCase,
        { provide: ProductDatabaseRepository, useValue: mockProductRepo },
      ],
    }).compile();

    useCase = module.get(DeleteProductUseCase);
  });

  it('should return NotFoundError if product does not exist', async () => {
    mockProductRepo.findById.mockResolvedValue(right(null));

    const result = await useCase.execute({ productId: 'prod-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return ForbiddenError if user is not the seller', async () => {
    mockProductRepo.findById.mockResolvedValue(
      right({ id: 'prod-1', sellerId: 'other-seller' }),
    );

    const result = await useCase.execute({ productId: 'prod-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('should soft delete product successfully if user is seller', async () => {
    mockProductRepo.findById.mockResolvedValue(
      right({ id: 'prod-1', sellerId: 'user-1' }),
    );
    mockProductRepo.delete.mockResolvedValue(right(undefined));

    const result = await useCase.execute({ productId: 'prod-1', userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockProductRepo.delete).toHaveBeenCalledWith('prod-1');
  });

  it('should return error if repository delete fails', async () => {
    mockProductRepo.findById.mockResolvedValue(
      right({ id: 'prod-1', sellerId: 'user-1' }),
    );
    mockProductRepo.delete.mockResolvedValue(left(new DatabaseError('DB Error')));

    const result = await useCase.execute({ productId: 'prod-1', userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
  });
});
