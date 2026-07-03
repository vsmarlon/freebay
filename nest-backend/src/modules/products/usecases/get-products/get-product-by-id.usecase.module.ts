import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { GetProductByIdUseCase } from './get-product-by-id.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    GetProductByIdUseCase,
  ],
  exports: [GetProductByIdUseCase],
})
export class GetProductByIdUseCaseModule {}
