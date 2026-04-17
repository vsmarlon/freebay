import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { PrismaFavoriteRepository } from './repositories/favorite.repository';

@Module({
  controllers: [FavoritesController],
  providers: [PrismaFavoriteRepository],
  exports: [PrismaFavoriteRepository],
})
export class FavoritesModule {}
