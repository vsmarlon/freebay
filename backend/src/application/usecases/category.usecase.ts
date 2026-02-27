import { Either, right } from '@/domain/either';
import { AppError } from '@/domain/errors';
import { ICategoryRepository } from '@/domain/repositories';
import { CategoryEntity } from '@/domain/entities';

export class GetCategoriesUseCase {
  constructor(private categoryRepository: ICategoryRepository) {}

  async execute(): Promise<Either<AppError, CategoryEntity[]>> {
    const categories = await this.categoryRepository.getCategoryTree();
    return right(categories);
  }
}

export class GetAllCategoriesUseCase {
  constructor(private categoryRepository: ICategoryRepository) {}

  async execute(): Promise<Either<AppError, CategoryEntity[]>> {
    const categories = await this.categoryRepository.getAllCategories();
    return right(categories);
  }
}

export class CreateCategoryUseCase {
  constructor(private categoryRepository: ICategoryRepository) {}

  async execute(data: {
    name: string;
    slug: string;
    parentId?: string;
  }): Promise<Either<AppError, CategoryEntity>> {
    const category = await this.categoryRepository.createCategory(data);
    return right(category);
  }
}
