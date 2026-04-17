import { Module } from '@nestjs/common';
import { WishlistController } from './wishlist.controller';
import { PrismaWishlistRepository } from './repositories/wishlist.repository';

@Module({
  controllers: [WishlistController],
  providers: [PrismaWishlistRepository],
  exports: [PrismaWishlistRepository],
})
export class WishlistModule {}
