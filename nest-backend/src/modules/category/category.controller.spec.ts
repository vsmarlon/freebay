import { Test, TestingModule } from '@nestjs/testing';
import { CategoryController } from './category.controller';
import { PrismaCategoryRepository } from './repositories/category.repository';

const mockCategoryRepository = {
  findAll: jest.fn(),
  findById: jest.fn(),
};

describe('CategoryController', () => {
  let controller: CategoryController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CategoryController],
      providers: [
        { provide: PrismaCategoryRepository, useValue: mockCategoryRepository },
      ],
    }).compile();

    controller = module.get<CategoryController>(CategoryController);
    jest.clearAllMocks();
  });

  it('should return all categories', async () => {
    mockCategoryRepository.findAll.mockResolvedValue([
      { id: 'cat-1', name: 'Electronics', slug: 'electronics', children: [] },
    ]);
    const result: any = await controller.findAll();
    expect(result.categories).toHaveLength(1);
  });

  it('should return category by id', async () => {
    mockCategoryRepository.findById.mockResolvedValue({ id: 'cat-1', name: 'Electronics' });
    const result: any = await controller.findOne('cat-1');
    expect(result.category).toBeDefined();
    expect(result.category.name).toBe('Electronics');
  });

  it('should return left error when category not found', async () => {
    mockCategoryRepository.findById.mockResolvedValue(null);
    const result = await controller.findOne('nonexistent');
    expect(result).toBeDefined();
  });
});
