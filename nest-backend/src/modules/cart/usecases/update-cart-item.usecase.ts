import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { CartRepository } from '../domain/repositories/cart.repository';

import { UpdateCartItemInput, UpdateCartItemOutput } from '../dtos/cart.dto';

@Injectable()
export class UpdateCartItemUseCase {
  constructor(private readonly cartRepository: CartRepository) {}

  async execute(input: UpdateCartItemInput): Promise<Either<AppError, UpdateCartItemOutput>> {
    if (!Number.isInteger(input.quantity) || input.quantity < 1 || input.quantity > 10) {
      return left(new BadRequestError('Quantidade deve ser entre 1 e 10'));
    }

    const existingResult = await this.cartRepository.findItem(input.userId, input.productId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return left(new NotFoundError('Item no carrinho'));

    const itemResult = await this.cartRepository.updateQuantity(input.userId, input.productId, input.quantity);
    if (isLeft(itemResult)) return left(itemResult.value);

    return right({ item: itemResult.value });
  }
}
