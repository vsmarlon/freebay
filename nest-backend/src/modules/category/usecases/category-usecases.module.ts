import { Module } from '@nestjs/common';
import { CategoryDatabaseRepository } from '../data/repositories/category-database.repository';
import { ListCategoriesUseCase } from './list-categories.usecase';
import { GetCategoryUseCase } from './get-category.usecase';

@Module({
  providers: [
    CategoryDatabaseRepository,
    ListCategoriesUseCase,
    GetCategoryUseCase,
  ],
  exports: [
    ListCategoriesUseCase,
    GetCategoryUseCase,
  ],
})
export class CategoryUseCasesModule {}
