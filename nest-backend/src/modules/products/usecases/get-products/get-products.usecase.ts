import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductQueryDTO } from '../../dtos/product.dto';
import { ProductListPayload } from '../../types/product.types';

@Injectable()
export class GetProductsUseCase {
  constructor(private readonly productRepository: ProductRepository) {}

  async execute(query: ProductQueryDTO): Promise<Either<AppError, { products: ProductListPayload[]; nextCursor: string | null }>> {
    const limit = query.limit ?? 20;
    const result = await this.productRepository.findMany({
      cursor: query.cursor,
      limit,
      search: query.search,
      categoryId: query.category,
      minPrice: query.minPrice,
      maxPrice: query.maxPrice,
    });

    if (result.isLeft()) return left(result.value);
    const products = result.value;

    return right({
      products,
      nextCursor: products.length === limit ? products[products.length - 1]?.id : null,
    });
  }
}
