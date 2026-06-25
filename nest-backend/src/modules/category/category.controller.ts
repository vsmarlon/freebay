import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaCategoryRepository } from './repositories/category.repository';

@ApiTags('Categories')
@Controller('categories')
export class CategoryController {
  constructor(private categoryRepository: PrismaCategoryRepository) {}

  @Get()
  @ApiDoc({
    summary: 'List all categories',
  })
  async findAll() {
    const categories = await this.categoryRepository.findAll();
    return { categories };
  }

  @Get(':id')
  @ApiDoc({
    summary: 'Get category by ID',
    params: [{ name: 'id', description: 'Category UUID' }],
    errors: [{ status: 404, description: 'Category not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const category = await this.categoryRepository.findById(id);
    if (!category) {
      return left(new AppError('NOT_FOUND', 'Categoria não encontrada'));
    }
    return { category };
  }
}
