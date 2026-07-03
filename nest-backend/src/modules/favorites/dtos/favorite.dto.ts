import { ApiProperty } from '@nestjs/swagger';

export class FavoritesResponse {
  @ApiProperty({ example: [{ id: 'uuid', title: 'iPhone 15', price: 15000 }] })
  readonly products: FavoriteProduct[];
}

export interface FavoriteProduct {
  id: string;
  title: string;
  price: number;
}

export class CheckFavoriteResponse {
  @ApiProperty({ example: true })
  readonly isFavorited: boolean;
}

export class ToggleFavoriteResponse {
  @ApiProperty({ example: true })
  readonly favorited: boolean;
}
