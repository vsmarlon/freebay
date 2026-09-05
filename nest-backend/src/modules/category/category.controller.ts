import { Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetPublic } from '@/shared/decorators';
import { CategoryService } from './category.service';

@ApiTags('Categories')
@Controller('categories')
export class CategoryController {
  constructor(private readonly categoryService: CategoryService) {}

  @GetPublic('List all categories')
  async findAll() {
    return this.categoryService.findAll();
  }

  @GetPublic(':id', {
    summary: 'Get category by ID',
    params: [{ name: 'id', description: 'Category UUID' }],
    errors: [{ status: 404, description: 'Category not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.categoryService.findOne(id);
  }
}
