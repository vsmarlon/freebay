import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CategoryRepository } from '../domain/repositories/category.repository';
import { CategoryWithChildren } from '../types/category.types';

@Injectable()
export class ListCategoriesUseCase {
  constructor(private readonly categoryRepository: CategoryRepository) {}

  async execute(): Promise<Either<AppError, { categories: CategoryWithChildren[] }>> {
    const result = await this.categoryRepository.findAll();
    if (isLeft(result)) return left(result.value);
    return right({ categories: result.value });
  }
}
