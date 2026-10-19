import { Module } from '@nestjs/common';
import { CategoryController } from './category.controller';
import { CategoryUseCasesModule } from './usecases/category-usecases.module';

@Module({
  imports: [CategoryUseCasesModule],
  controllers: [CategoryController],
})
export class CategoryModule {}
