import { Module } from '@nestjs/common';
import { CategoryRepository } from '../domain/repositories/category.repository';
import { CategoryDatabaseRepository } from '../data/repositories/category-database.repository';
import { ListCategoriesUseCase } from './list-categories.usecase';
import { GetCategoryUseCase } from './get-category.usecase';

@Module({
  providers: [
    { provide: CategoryRepository, useClass: CategoryDatabaseRepository },
    ListCategoriesUseCase,
    GetCategoryUseCase,
  ],
  exports: [
    ListCategoriesUseCase,
    GetCategoryUseCase,
  ],
})
export class CategoryUseCasesModule {}
