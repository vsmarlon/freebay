import { Module } from '@nestjs/common';
import { CategoryController } from './category.controller';
import { CategoryUseCasesModule } from './usecases/category-usecases.module';
import { CategoryService } from './category.service';

@Module({
  imports: [CategoryUseCasesModule],
  controllers: [CategoryController],
  providers: [CategoryService],
  exports: [CategoryService],
})
export class CategoryModule {}
