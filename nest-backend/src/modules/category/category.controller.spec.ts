import { Test, TestingModule } from '@nestjs/testing';
import { CategoryController } from './category.controller';
import { CategoryService } from './api/category.service';

const mockService = {
  findAll: jest.fn(),
  findOne: jest.fn(),
};

describe('CategoryController', () => {
  let controller: CategoryController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CategoryController],
      providers: [
        { provide: CategoryService, useValue: mockService },
      ],
    }).compile();

    controller = module.get<CategoryController>(CategoryController);
    jest.clearAllMocks();
  });

  it('should return all categories', async () => {
    mockService.findAll.mockResolvedValue({
      categories: [{ id: 'cat-1', name: 'Electronics', slug: 'electronics', children: [] }],
    });
    const result = await controller.findAll();
    expect(result.categories).toHaveLength(1);
  });

  it('should return category by id', async () => {
    mockService.findOne.mockResolvedValue({ category: { id: 'cat-1', name: 'Electronics' } });
    const result = await controller.findOne('cat-1');
    expect(result.category).toBeDefined();
    expect(result.category.name).toBe('Electronics');
  });

  it('should throw when category not found', async () => {
    mockService.findOne.mockRejectedValue(new Error('Not found'));
    await expect(controller.findOne('nonexistent')).rejects.toThrow();
  });
});
