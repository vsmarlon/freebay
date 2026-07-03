import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
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
      return left(new AppError('NOT_FOUND', 'Categoria não encontrada'));
    }
    return right({ category: result.value });
  }
}
