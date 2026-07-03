import { Module } from '@nestjs/common';
import { CategoryController } from './category.controller';
import { CategoryUseCasesModule } from './usecases/category-usecases.module';
import { CategoryApiModule } from './api/category-api.module';

@Module({
  imports: [CategoryUseCasesModule, CategoryApiModule],
  controllers: [CategoryController],
})
export class CategoryModule {}
