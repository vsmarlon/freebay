import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesUseCasesModule } from './usecases/favorites-usecases.module';

@Module({
  imports: [FavoritesUseCasesModule],
  controllers: [FavoritesController],
  exports: [FavoritesUseCasesModule],
})
export class FavoritesModule {}
