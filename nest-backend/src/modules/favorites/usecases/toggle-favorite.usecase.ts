import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FavoriteRepository } from '../domain/repositories/favorite.repository';

@Injectable()
export class ToggleFavoriteUseCase {
  constructor(private readonly favoriteRepository: FavoriteRepository) {}

  async execute(userId: string, productId: string): Promise<Either<AppError, { favorited: boolean }>> {
    const productResult = await this.favoriteRepository.findProductById(productId);
    if (isLeft(productResult)) {
      return left(productResult.value);
    }
    if (!productResult.value || productResult.value.status !== 'ACTIVE') {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado', 404));
    }

    if (productResult.value.sellerId === userId) {
      return left(new AppError('FORBIDDEN', 'Você não pode favoritar seu próprio produto', 403));
    }

    const existingResult = await this.favoriteRepository.findByUserAndProduct(userId, productId);
    if (isLeft(existingResult)) {
      return left(existingResult.value);
    }

    if (existingResult.value) {
      const deleteResult = await this.favoriteRepository.delete(userId, productId);
      if (isLeft(deleteResult)) {
        return left(deleteResult.value);
      }
      return right({ favorited: false });
    }

    const createResult = await this.favoriteRepository.create(userId, productId);
    if (isLeft(createResult)) {
      return left(createResult.value);
    }

    return right({ favorited: true });
  }
}
