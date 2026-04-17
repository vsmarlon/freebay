import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Controller('categories')
export class CategoryController {
  constructor(private prisma: PrismaService) {}

  @Get()
  async findAll() {
    const categories = await this.prisma.category.findMany({
      orderBy: { name: 'asc' },
    });
    return { categories };
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) {
      return left(new AppError('NOT_FOUND', 'Categoria não encontrada'));
    }
    return { category };
  }
}
