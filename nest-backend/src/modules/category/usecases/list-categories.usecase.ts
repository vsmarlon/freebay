import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CategoryDatabaseRepository } from '../data/repositories/category-database.repository';
import { CategoryWithChildren } from '../types/category.types';

@Injectable()
export class ListCategoriesUseCase {
  constructor(private readonly categoryRepository: CategoryDatabaseRepository) {}

  async execute(): Promise<Either<AppError, { categories: CategoryWithChildren[] }>> {
    const result = await this.categoryRepository.findAll();
    if (result.isLeft()) return left(result.value);
    return right({ categories: result.value });
  }
}
