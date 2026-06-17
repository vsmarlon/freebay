import { ApiProperty } from '@nestjs/swagger';

export class FavoritesResponse {
  @ApiProperty({ example: [{ id: 'uuid', title: 'iPhone 15', price: 15000 }] })
  products: unknown[];
}

export class CheckFavoriteResponse {
  @ApiProperty({ example: true })
  isFavorited: boolean;
}

export class ToggleFavoriteResponse {
  @ApiProperty({ example: true })
  favorited: boolean;
}
