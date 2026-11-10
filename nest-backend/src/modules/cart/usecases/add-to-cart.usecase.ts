import { Injectable } from '@nestjs/common';
import { ProductStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';

import { AddToCartInput, AddToCartOutput } from '../dtos/cart.dto';

@Injectable()
export class AddToCartUseCase {
  constructor(private readonly cartRepository: CartDatabaseRepository) {}

  async execute(input: AddToCartInput): Promise<Either<AppError, AddToCartOutput>> {
    const quantity = Math.min(Math.max(input.quantity, 1), 10);

    const productResult = await this.cartRepository.findProductById(input.productId);
    if (productResult.isLeft()) return left(productResult.value);
    if (!productResult.value || productResult.value.status !== ProductStatus.ACTIVE) {
      return left(new NotFoundError('Produto'));
    }
    if (productResult.value.sellerId === input.userId) {
      return left(new ForbiddenError('Você não pode adicionar seu próprio produto ao carrinho'));
    }

    const existingResult = await this.cartRepository.findItem(input.userId, input.productId);
    if (existingResult.isLeft()) return left(existingResult.value);
    const resultingQuantity = (existingResult.value?.quantity ?? 0) + quantity;
    const availableStock = Math.max(productResult.value.quantity - productResult.value.soldCount, 0);
    if (resultingQuantity > availableStock) {
      return left(new BadRequestError('Quantidade indisponível em estoque'));
    }

    const itemResult = await this.cartRepository.addOrIncrement(input.userId, input.productId, quantity);
    if (itemResult.isLeft()) return left(itemResult.value);

    return right({ item: itemResult.value });
  }
}
