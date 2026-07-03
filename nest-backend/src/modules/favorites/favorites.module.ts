import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesUseCasesModule } from './usecases/favorites-usecases.module';
import { FavoritesApiModule } from './api/favorites-api.module';

@Module({
  imports: [FavoritesUseCasesModule, FavoritesApiModule],
  controllers: [FavoritesController],
})
export class FavoritesModule {}
