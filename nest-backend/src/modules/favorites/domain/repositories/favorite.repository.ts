import { RepositoryResponse } from '@/shared/core/either';
import { Favorite, Product } from '@prisma/client';
import { FavoriteWithProduct } from '../../types/favorite.types';

export abstract class FavoriteRepository {
  abstract findByUserAndProduct(userId: string, productId: string): RepositoryResponse<Favorite | null>;
  abstract create(userId: string, productId: string): RepositoryResponse<Favorite>;
  abstract delete(userId: string, productId: string): RepositoryResponse<Favorite>;
  abstract getUserFavorites(userId: string): RepositoryResponse<FavoriteWithProduct[]>;
  abstract findProductById(productId: string): RepositoryResponse<Pick<Product, 'id' | 'sellerId' | 'status'> | null>;
}
