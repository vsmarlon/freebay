import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';

import { RemoveFromCartInput } from '../dtos/cart.dto';

@Injectable()
export class RemoveFromCartUseCase {
  constructor(private readonly cartRepository: CartDatabaseRepository) {}

  async execute(input: RemoveFromCartInput): Promise<Either<AppError, void>> {
    const existingResult = await this.cartRepository.findItem(input.userId, input.productId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return left(new NotFoundError('Item no carrinho'));

    const result = await this.cartRepository.remove(input.userId, input.productId);
    if (isLeft(result)) return left(result.value);

    return right(undefined);
  }
}
