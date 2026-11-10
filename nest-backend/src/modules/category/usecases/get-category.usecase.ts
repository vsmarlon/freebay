import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { Category } from '@prisma/client';
import { CategoryDatabaseRepository } from '../data/repositories/category-database.repository';

@Injectable()
export class GetCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryDatabaseRepository) {}

  async execute(id: string): Promise<Either<AppError, { category: Category }>> {
    const result = await this.categoryRepository.findById(id);
    if (result.isLeft()) {
      return left(result.value);
    }
    if (!result.value) {
      return left(new NotFoundError('Categoria'));
    }
    return right({ category: result.value });
  }
}
