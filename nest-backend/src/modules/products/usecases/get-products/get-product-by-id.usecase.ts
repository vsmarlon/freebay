import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDetailPayload } from '../../types/product.types';

@Injectable()
export class GetProductByIdUseCase {
  constructor(private readonly productRepository: ProductRepository) {}

  async execute(id: string): Promise<Either<AppError, { product: ProductDetailPayload }>> {
    const result = await this.productRepository.findById(id);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new NotFoundError('Product'));

    return right({ product: result.value });
  }
}
