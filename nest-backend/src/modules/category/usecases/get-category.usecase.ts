import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { Category } from '@prisma/client';
import { CategoryRepository } from '../domain/repositories/category.repository';

@Injectable()
export class GetCategoryUseCase {
  constructor(private readonly categoryRepository: CategoryRepository) {}

  async execute(id: string): Promise<Either<AppError, { category: Category }>> {
    const result = await this.categoryRepository.findById(id);
    if (isLeft(result)) {
      return left(result.value);
    }
    if (!result.value) {
      return left(new NotFoundError('Categoria'));
    }
    return right({ category: result.value });
  }
}
