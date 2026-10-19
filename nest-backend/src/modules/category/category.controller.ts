import { Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetPublic } from '@/shared/decorators';
import { ListCategoriesUseCase } from './usecases/list-categories.usecase';
import { GetCategoryUseCase } from './usecases/get-category.usecase';
import { unwrap } from '@/shared/http/unwrap';

@ApiTags('Categories')
@Controller('categories')
export class CategoryController {
  constructor(
    private readonly listCategoriesUseCase: ListCategoriesUseCase,
    private readonly getCategoryUseCase: GetCategoryUseCase,
  ) {}

  @GetPublic('List all categories')
  async findAll() {
    return unwrap(await this.listCategoriesUseCase.execute());
  }

  @GetPublic(':id', {
    summary: 'Get category by ID',
    params: [{ name: 'id', description: 'Category UUID' }],
    errors: [{ status: 404, description: 'Category not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return unwrap(await this.getCategoryUseCase.execute(id));
  }
}
