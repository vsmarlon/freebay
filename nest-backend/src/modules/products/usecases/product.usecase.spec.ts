import { Test, TestingModule } from '@nestjs/testing';
import { CreateProductUseCase, DeleteProductUseCase } from './product.usecase';
import { PrismaProductRepository } from '../repositories/product.repository';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';

describe('CreateProductUseCase', () => {
  let sut: CreateProductUseCase;
  let mockProductRepository: any;

  beforeEach(async () => {
    mockProductRepository = {
      create: jest.fn().mockResolvedValue({
        id: 'product-123',
        title: 'Test Product',
        description: 'Test Description',
        price: 10000,
        condition: 'NEW',
        categoryId: 'category-123',
        sellerId: 'seller-123',
        status: 'ACTIVE',
        createdAt: new Date(),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateProductUseCase,
        { provide: PrismaProductRepository, useValue: mockProductRepository },
      ],
    }).compile();

    sut = module.get<CreateProductUseCase>(CreateProductUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a new product', async () => {
    const input = {
      sellerId: 'seller-123',
      title: 'Test Product',
      description: 'Test Description',
      price: 10000,
      condition: 'NEW' as const,
      categoryId: 'category-123',
      images: ['http://example.com/image.jpg'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.title).toBe('Test Product');
      expect(result.value.price).toBe(10000);
    }
    expect(mockProductRepository.create).toHaveBeenCalled();
  });

  it('should create product with USED condition', async () => {
    mockProductRepository.create = jest.fn().mockResolvedValue({
      id: 'product-123',
      title: 'Used Product',
      description: 'A used item',
      price: 5000,
      condition: 'USED',
      categoryId: 'category-123',
      sellerId: 'seller-123',
      status: 'ACTIVE',
      createdAt: new Date(),
    });

    const input = {
      sellerId: 'seller-123',
      title: 'Used Product',
      description: 'A used item',
      price: 5000,
      condition: 'USED' as const,
      categoryId: 'category-123',
      images: ['http://example.com/image.jpg'],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.condition).toBe('USED');
    }
  });

  it('should create product with multiple images', async () => {
    const input = {
      sellerId: 'seller-123',
      title: 'Test Product',
      description: 'Test Description',
      price: 10000,
      condition: 'NEW' as const,
      categoryId: 'category-123',
      images: [
        'http://example.com/image1.jpg',
        'http://example.com/image2.jpg',
        'http://example.com/image3.jpg',
      ],
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockProductRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        images: {
          create: expect.arrayContaining([
            expect.objectContaining({ url: 'http://example.com/image1.jpg', order: 0 }),
            expect.objectContaining({ url: 'http://example.com/image2.jpg', order: 1 }),
            expect.objectContaining({ url: 'http://example.com/image3.jpg', order: 2 }),
          ]),
        },
      }),
    );
  });
});

describe('DeleteProductUseCase', () => {
  let sut: DeleteProductUseCase;
  let mockProductRepository: any;

  beforeEach(async () => {
    mockProductRepository = {
      findById: jest.fn(),
      delete: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteProductUseCase,
        { provide: PrismaProductRepository, useValue: mockProductRepository },
      ],
    }).compile();

    sut = module.get<DeleteProductUseCase>(DeleteProductUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should delete a product when user is the seller', async () => {
    mockProductRepository.findById.mockResolvedValue({
      id: 'product-123',
      sellerId: 'user-123',
    });

    const input = {
      productId: 'product-123',
      userId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.deleted).toBe(true);
    }
    expect(mockProductRepository.delete).toHaveBeenCalledWith('product-123');
  });

  it('should return error if product not found', async () => {
    mockProductRepository.findById.mockResolvedValue(null);

    const input = {
      productId: 'product-123',
      userId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return error if user is not the seller', async () => {
    mockProductRepository.findById.mockResolvedValue({
      id: 'product-123',
      sellerId: 'other-user-123',
    });

    const input = {
      productId: 'product-123',
      userId: 'user-123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(ForbiddenError);
    }
  });
});
