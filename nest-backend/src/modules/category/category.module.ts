import { Module } from '@nestjs/common';
import { CategoryController } from './category.controller';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaCategoryRepository } from './repositories/category.repository';

@Module({
  controllers: [CategoryController],
  providers: [PrismaService, PrismaCategoryRepository],
})
export class CategoryModule {}
