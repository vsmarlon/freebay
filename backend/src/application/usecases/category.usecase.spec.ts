import { GetCategoriesUseCase, CreateCategoryUseCase } from './category.usecase';
import { ICategoryRepository } from '@/domain/repositories';
import { CategoryEntity } from '@/domain/entities';

const mockCategoryRepository: jest.Mocked<ICategoryRepository> = {
  getCategoryTree: jest.fn(),
  getAllCategories: jest.fn(),
  getCategoryById: jest.fn(),
  createCategory: jest.fn(),
};

const mockCategory: CategoryEntity = {
  id: 'cat-1',
  name: 'Eletrônicos',
  slug: 'eletronicos',
  parentId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  children: [],
};

describe('GetCategoriesUseCase', () => {
  let sut: GetCategoriesUseCase;

  beforeEach(() => {
    sut = new GetCategoriesUseCase(mockCategoryRepository);
    jest.clearAllMocks();
  });

  it('should return right with category tree', async () => {
    mockCategoryRepository.getCategoryTree.mockResolvedValue([mockCategory]);

    const result = await sut.execute();

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(1);
      expect(result.value[0].name).toBe('Eletrônicos');
    }
  });

  it('should return right with empty list when no categories', async () => {
    mockCategoryRepository.getCategoryTree.mockResolvedValue([]);

    const result = await sut.execute();

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(0);
    }
  });
});

describe('CreateCategoryUseCase', () => {
  let sut: CreateCategoryUseCase;

  beforeEach(() => {
    sut = new CreateCategoryUseCase(mockCategoryRepository);
    jest.clearAllMocks();
  });

  it('should create and return a category', async () => {
    mockCategoryRepository.createCategory.mockResolvedValue(mockCategory);

    const result = await sut.execute({ name: 'Eletrônicos', slug: 'eletronicos' });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.slug).toBe('eletronicos');
    }
    expect(mockCategoryRepository.createCategory).toHaveBeenCalledWith({
      name: 'Eletrônicos',
      slug: 'eletronicos',
    });
  });

  it('should pass parentId when provided', async () => {
    const childCategory = { ...mockCategory, id: 'cat-2', parentId: 'cat-1' };
    mockCategoryRepository.createCategory.mockResolvedValue(childCategory);

    const result = await sut.execute({ name: 'Celulares', slug: 'celulares', parentId: 'cat-1' });

    expect(result._tag).toBe('right');
    expect(mockCategoryRepository.createCategory).toHaveBeenCalledWith({
      name: 'Celulares',
      slug: 'celulares',
      parentId: 'cat-1',
    });
  });
});
