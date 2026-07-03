import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductListPayload } from '../../types/product.types';

@Injectable()
export class GetMyProductsUseCase {
  constructor(private readonly productRepository: ProductRepository) {}

  async execute(sellerId: string): Promise<Either<AppError, { products: ProductListPayload[] }>> {
    const result = await this.productRepository.findBySellerId(sellerId);
    if (result.isLeft()) return left(result.value);

    return right({ products: result.value });
  }
}
