import { useQuery } from '@tanstack/react-query';
import { userKey } from '../../core/query-client';
import { productApi } from './api';
import type { ProductPage } from './types';

export type CatalogFilters = {
  q: string;
  categoryId: string;
  minPrice: string;
  maxPrice: string;
  condition: string;
  sort: string;
  cursor?: string;
};
export function catalogQuery(filters: CatalogFilters): URLSearchParams {
  const query = new URLSearchParams({ limit: '20' });
  if (filters.q.trim()) query.set('search', filters.q.trim());
  if (filters.categoryId) query.set('category', filters.categoryId);
  if (filters.minPrice !== '') query.set('minPrice', String(parseCentsFilter(filters.minPrice)));
  if (filters.maxPrice !== '') query.set('maxPrice', String(parseCentsFilter(filters.maxPrice)));
  if (filters.condition) query.set('condition', filters.condition);
  if (filters.sort) query.set('sort', filters.sort);
  if (filters.cursor) query.set('cursor', filters.cursor);
  return query;
}

export function parseCentsFilter(value: string): number {
  if (!/^\d+$/.test(value)) throw new TypeError('Price filters must be integer cents');
  const cents = Number(value);
  if (!Number.isSafeInteger(cents)) throw new TypeError('Price filter is outside the safe range');
  return cents;
}

export function appendPage(current: ProductPage, next: ProductPage): ProductPage {
  const seen = new Set(current.products.map((product) => product.id));
  return {
    products: [...current.products, ...next.products.filter((product) => !seen.has(product.id))],
    nextCursor: next.nextCursor,
  };
}

// Favorites and follows hang off the `user` root so list screens can invalidate
// them by prefix; signed-out viewers keep a stable placeholder key.
export const productKeys = {
  favorite: (userId: string | undefined, productId: string) =>
    userId
      ? userKey(userId, 'favorites', productId)
      : (['anonymous', 'favorite', productId] as const),
  follow: (userId: string | undefined, sellerId: string) =>
    userId ? userKey(userId, 'follow', sellerId) : (['anonymous', 'follow', sellerId] as const),
  seller: (sellerId: string) => ['public', 'seller', sellerId] as const,
  sellerReviews: (sellerId: string) => ['public', 'reviews', sellerId] as const,
};

// Enabled for any signed-in viewer: the detail page mounts product actions only
// for non-owners (display gate), and the backend remains the authorization boundary.
export function useFavoriteState(userId: string | undefined, productId: string) {
  return useQuery({
    queryKey: productKeys.favorite(userId, productId),
    enabled: Boolean(userId),
    queryFn: ({ signal }) => productApi.favoriteState(productId, signal),
  });
}

export function useFollowState(userId: string | undefined, sellerId: string) {
  return useQuery({
    queryKey: productKeys.follow(userId, sellerId),
    enabled: Boolean(userId),
    queryFn: ({ signal }) => productApi.followState(sellerId, signal),
  });
}

export function useSellerProfile(sellerId: string) {
  return useQuery({
    queryKey: productKeys.seller(sellerId),
    queryFn: ({ signal }) => productApi.seller(sellerId, signal),
  });
}

export function useSellerReviews(sellerId: string) {
  return useQuery({
    queryKey: productKeys.sellerReviews(sellerId),
    queryFn: ({ signal }) => productApi.reviews(sellerId, signal),
  });
}
