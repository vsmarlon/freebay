import { Module } from '@nestjs/common';
import { FavoriteDatabaseRepository } from '../data/repositories/favorite-database.repository';
import { GetFavoritesUseCase } from './get-favorites.usecase';
import { CheckFavoriteUseCase } from './check-favorite.usecase';
import { ToggleFavoriteUseCase } from './toggle-favorite.usecase';

@Module({
  providers: [
    FavoriteDatabaseRepository,
    GetFavoritesUseCase,
    CheckFavoriteUseCase,
    ToggleFavoriteUseCase,
  ],
  exports: [
    GetFavoritesUseCase,
    CheckFavoriteUseCase,
    ToggleFavoriteUseCase,
  ],
})
export class FavoritesUseCasesModule {}
