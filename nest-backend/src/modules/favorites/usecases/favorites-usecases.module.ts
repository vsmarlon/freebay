import { Module } from '@nestjs/common';
import { FavoriteRepository } from '../domain/repositories/favorite.repository';
import { FavoriteDatabaseRepository } from '../data/repositories/favorite-database.repository';
import { GetFavoritesUseCase } from './get-favorites.usecase';
import { CheckFavoriteUseCase } from './check-favorite.usecase';
import { ToggleFavoriteUseCase } from './toggle-favorite.usecase';

@Module({
  providers: [
    { provide: FavoriteRepository, useClass: FavoriteDatabaseRepository },
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
