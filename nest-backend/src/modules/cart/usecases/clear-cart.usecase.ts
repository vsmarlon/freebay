import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';

@Injectable()
export class ClearCartUseCase {
  constructor(private readonly cartRepository: CartDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, void>> {
    const result = await this.cartRepository.clear(userId);
    if (isLeft(result)) return left(result.value);

    return right(undefined);
  }
}
