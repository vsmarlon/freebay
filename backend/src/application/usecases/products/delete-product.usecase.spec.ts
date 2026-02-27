import { DeleteProductUseCase } from './delete-product.usecase';
import { IProductRepository } from '@/domain/repositories';
import { ProductEntity } from '@/domain/entities';

const mockProduct: ProductEntity = {
  id: 'prod-1',
  title: 'Test Product',
  description: 'A test product description',
  price: 5000,
  condition: 'NEW',
  categoryId: null,
  status: 'ACTIVE',
  sellerId: 'seller-1',
  postId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
};

const mockProductRepository: jest.Mocked<IProductRepository> = {
  findById: jest.fn(),
  findBySellerId: jest.fn(),
  findAll: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  softDelete: jest.fn(),
};

describe('DeleteProductUseCase', () => {
  let sut: DeleteProductUseCase;

  beforeEach(() => {
    sut = new DeleteProductUseCase(mockProductRepository);
    jest.clearAllMocks();
  });

  it('should soft delete and return right when product exists', async () => {
    mockProductRepository.findById.mockResolvedValue(mockProduct);
    mockProductRepository.softDelete.mockResolvedValue();

    const result = await sut.execute('prod-1');

    expect(result._tag).toBe('right');
    expect(mockProductRepository.findById).toHaveBeenCalledWith('prod-1');
    expect(mockProductRepository.softDelete).toHaveBeenCalledWith('prod-1');
  });

  it('should return left(NotFoundError) when product does not exist', async () => {
    mockProductRepository.findById.mockResolvedValue(null);

    const result = await sut.execute('nonexistent');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
    expect(mockProductRepository.softDelete).not.toHaveBeenCalled();
  });
});
