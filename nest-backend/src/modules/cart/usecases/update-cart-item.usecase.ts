import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';

import { UpdateCartItemInput, UpdateCartItemOutput } from '../dtos/cart.dto';

@Injectable()
export class UpdateCartItemUseCase {
  constructor(private readonly cartRepository: CartDatabaseRepository) {}

  async execute(input: UpdateCartItemInput): Promise<Either<AppError, UpdateCartItemOutput>> {
    if (!Number.isInteger(input.quantity) || input.quantity < 1 || input.quantity > 10) {
      return left(new BadRequestError('Quantidade deve ser entre 1 e 10'));
    }

    const existingResult = await this.cartRepository.findItem(input.userId, input.productId);
    if (existingResult.isLeft()) return left(existingResult.value);
    if (!existingResult.value) return left(new NotFoundError('Item no carrinho'));

    const itemResult = await this.cartRepository.updateQuantity(input.userId, input.productId, input.quantity);
    if (itemResult.isLeft()) return left(itemResult.value);

    return right({ item: itemResult.value });
  }
}
