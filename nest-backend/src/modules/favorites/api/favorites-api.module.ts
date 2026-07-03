import { Module } from '@nestjs/common';
import { FavoritesUseCasesModule } from '../usecases/favorites-usecases.module';
import { FavoritesService } from './favorites.service';

@Module({
  imports: [FavoritesUseCasesModule],
  providers: [FavoritesService],
  exports: [FavoritesService],
})
export class FavoritesApiModule {}
