import {
  CreateProductUseCase,
  SearchProductsUseCase,
  GetProductUseCase,
} from './create-product.usecase';
import { IProductRepository } from '@/domain/repositories';
import { ProductEntity } from '@/domain/entities';

const mockProduct: ProductEntity = {
  id: 'prod-1',
  title: 'Test Product',
  description: 'A test product description',
  price: 5000,
  condition: 'NEW',
  categoryId: 'cat-1',
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

describe('CreateProductUseCase', () => {
  let sut: CreateProductUseCase;

  beforeEach(() => {
    sut = new CreateProductUseCase(mockProductRepository);
    jest.clearAllMocks();
  });

  it('should create a product and return right', async () => {
    mockProductRepository.create.mockResolvedValue(mockProduct);

    const result = await sut.execute({
      title: 'Test Product',
      description: 'A test product description',
      price: 5000,
      condition: 'NEW',
      sellerId: 'seller-1',
    });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.title).toBe('Test Product');
      expect(result.value.sellerId).toBe('seller-1');
    }
    expect(mockProductRepository.create).toHaveBeenCalledTimes(1);
  });

  it('should set categoryId to null when not provided', async () => {
    mockProductRepository.create.mockResolvedValue(mockProduct);

    await sut.execute({
      title: 'Test',
      description: 'Description here',
      price: 1000,
      condition: 'USED',
      sellerId: 'seller-1',
    });

    expect(mockProductRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({ categoryId: null }),
    );
  });
});

describe('SearchProductsUseCase', () => {
  let sut: SearchProductsUseCase;

  beforeEach(() => {
    sut = new SearchProductsUseCase(mockProductRepository);
    jest.clearAllMocks();
  });

  it('should return right with products list', async () => {
    mockProductRepository.findAll.mockResolvedValue([mockProduct]);

    const result = await sut.execute({ limit: 20 });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].id).toBe('prod-1');
    }
  });

  it('should return right with empty list', async () => {
    mockProductRepository.findAll.mockResolvedValue([]);

    const result = await sut.execute({ search: 'nonexistent' });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(0);
    }
  });
});

describe('GetProductUseCase', () => {
  let sut: GetProductUseCase;

  beforeEach(() => {
    sut = new GetProductUseCase(mockProductRepository);
    jest.clearAllMocks();
  });

  it('should return right when product found', async () => {
    mockProductRepository.findById.mockResolvedValue(mockProduct);

    const result = await sut.execute('prod-1');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.id).toBe('prod-1');
    }
  });

  it('should return left(NotFoundError) when product not found', async () => {
    mockProductRepository.findById.mockResolvedValue(null);

    const result = await sut.execute('nonexistent');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
  });
});
