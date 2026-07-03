import { Module } from '@nestjs/common';
import { CategoryUseCasesModule } from '../usecases/category-usecases.module';
import { CategoryService } from './category.service';

@Module({
  imports: [CategoryUseCasesModule],
  providers: [CategoryService],
  exports: [CategoryService],
})
export class CategoryApiModule {}
