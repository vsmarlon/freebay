import { api } from '../../core/api';
import type { ProductSummary } from './types';

export type Favorite = { isFavorited: boolean };
export type FollowStatus = {
  isFollowing: boolean;
  followersCount: number;
  followingCount: number;
};
export type SellerProfile = { reputationScore: number; totalReviews: number };
export type ReviewList = {
  reviews: Array<{
    id: string;
    score: number;
    comment: string | null;
    reviewer: { displayName: string };
  }>;
  total: number;
  offset: number;
  limit: number;
};
export type Conversation = { conversationId: string };
export type FavoriteRecord = { id: string; product: ProductSummary };
export type FavoriteResponse =
  | FavoriteRecord[]
  | { products: Array<ProductSummary | FavoriteRecord> };
export type ReviewType = '' | 'BUYER_REVIEWING_SELLER' | 'SELLER_REVIEWING_BUYER';
export type ReviewPage = {
  reviews: Array<{
    id: string;
    score: number;
    comment: string | null;
    type: Exclude<ReviewType, ''>;
    createdAt: string;
    images: Array<{ id: string; url: string; order: number }>;
    reviewer: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean };
  }>;
  total: number;
  offset: number;
  limit: number;
};

export const productApi = {
  favoriteState: (productId: string, signal?: AbortSignal) =>
    api.get<Favorite>(`/favorites/check/${productId}`, { signal }),
  followState: (sellerId: string, signal?: AbortSignal) =>
    api.get<FollowStatus>(`/users/${sellerId}/is-following`, { signal }),
  seller: (sellerId: string, signal?: AbortSignal) =>
    api.get<SellerProfile>(`/users/${sellerId}`, { auth: false, signal }),
  reviews: (sellerId: string, signal?: AbortSignal) =>
    api.get<ReviewList>(`/reviews/users/${sellerId}?limit=5`, { auth: false, signal }),
  addFavorite: (productId: string) => api.post(`/favorites/${productId}`),
  addToCart: (productId: string, quantity: number) => api.post(`/cart/${productId}`, { quantity }),
  contactSeller: (input: { targetUserId: string; productId: string }) =>
    api.post<Conversation>('/chat/conversations', input),
  follow: (sellerId: string) => api.post(`/users/${sellerId}/follow`),
  unfollow: (sellerId: string) => api.patch(`/users/${sellerId}/unfollow`),
};

export const productEditorApi = {
  update: (productId: string, payload: Record<string, unknown>) =>
    api.patch(`/products/${productId}`, payload),
  create: (body: unknown) => api.post<{ id: string }>('/products', body),
  remove: (productId: string) => api.patch(`/products/${productId}/delete`),
};

export const favoritesApi = {
  list: (signal?: AbortSignal) => api.get<FavoriteResponse>('/favorites', { signal }),
  add: (productId: string) => api.post(`/favorites/${productId}`),
};

export const myProductsApi = {
  list: (signal?: AbortSignal) =>
    api.get<{ products: ProductSummary[] }>('/products/mine/all', { signal }),
};

export const userReviewsApi = {
  page: (userId: string, params: URLSearchParams, signal?: AbortSignal) =>
    api.get<ReviewPage>(`/reviews/users/${encodeURIComponent(userId)}?${params}`, { signal }),
};
