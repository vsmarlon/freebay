import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { DeleteProductInput } from '../../dtos/product.dto';

@Injectable()
export class DeleteProductUseCase {
  constructor(private readonly productRepository: ProductRepository) {}

  async execute(input: DeleteProductInput): Promise<Either<AppError, void>> {
    const product = await this.productRepository.findById(input.productId);
    if (product.isLeft()) return left(product.value);
    if (!product.value) return left(new NotFoundError('Product'));

    if (product.value.sellerId !== input.userId) {
      return left(new ForbiddenError('Você não pode excluir este produto'));
    }

    const deleted = await this.productRepository.delete(input.productId);
    if (deleted.isLeft()) return left(deleted.value);

    return right(undefined);
  }
}
