import { RepositoryResponse } from '@/shared/core/either';
import { Category } from '@prisma/client';
import { CategoryWithChildren } from '../../types/category.types';

export abstract class CategoryRepository {
  abstract findAll(): RepositoryResponse<CategoryWithChildren[]>;
  abstract findById(id: string): RepositoryResponse<Category | null>;
}
