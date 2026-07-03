import { Injectable } from '@nestjs/common';
import { isLeft } from '@/shared/core/either';
import { ListCategoriesUseCase } from './usecases/list-categories.usecase';
import { GetCategoryUseCase } from './usecases/get-category.usecase';

@Injectable()
export class CategoryService {
  constructor(
    private readonly listCategoriesUseCase: ListCategoriesUseCase,
    private readonly getCategoryUseCase: GetCategoryUseCase,
  ) {}

  async findAll() {
    const result = await this.listCategoriesUseCase.execute();
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  async findOne(id: string) {
    const result = await this.getCategoryUseCase.execute(id);
    if (isLeft(result)) throw result.value;
    return result.value;
  }
}
