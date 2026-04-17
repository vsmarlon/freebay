import { Module } from '@nestjs/common';
import { ProductsController } from './products.controller';
import { CreateProductUseCase, DeleteProductUseCase, UpdateProductUseCase } from './usecases/product.usecase';
import { PrismaProductRepository } from './repositories/product.repository';

@Module({
  controllers: [ProductsController],
  providers: [
    CreateProductUseCase,
    UpdateProductUseCase,
    DeleteProductUseCase,
    PrismaProductRepository,
  ],
  exports: [PrismaProductRepository],
})
export class ProductsModule {}
