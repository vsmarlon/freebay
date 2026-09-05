import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { CartRepository } from '../domain/repositories/cart.repository';

import { AddToCartInput, AddToCartOutput } from '../dtos/cart.dto';

@Injectable()
export class AddToCartUseCase {
  constructor(private readonly cartRepository: CartRepository) {}

  async execute(input: AddToCartInput): Promise<Either<AppError, AddToCartOutput>> {
    const quantity = Math.min(Math.max(input.quantity, 1), 10);

    const productResult = await this.cartRepository.findProductById(input.productId);
    if (isLeft(productResult)) return left(productResult.value);
    if (!productResult.value || productResult.value.status !== 'ACTIVE') {
      return left(new NotFoundError('Produto'));
    }
    if (productResult.value.sellerId === input.userId) {
      return left(new ForbiddenError('Você não pode adicionar seu próprio produto ao carrinho'));
    }

    const itemResult = await this.cartRepository.addOrIncrement(input.userId, input.productId, quantity);
    if (isLeft(itemResult)) return left(itemResult.value);

    return right({ item: itemResult.value });
  }
}
