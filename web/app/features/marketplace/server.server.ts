import type { ProductPage, ProductSummary, Category } from './types';
import { ApiError } from '../../core/api';

function backendOrigin() {
  const origin = process.env.BACKEND_URL;
  if (!origin) throw new Error('BACKEND_URL is not configured for public marketplace SSR');
  return origin.replace(/\/$/, '');
}

async function publicGet<T>(path: string): Promise<T> {
  const response = await fetch(`${backendOrigin()}${path}`, { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(10_000) });
  if (!response.ok) throw new ApiError('Marketplace request failed', response.status);
  const body: unknown = await response.json();
  if (body && typeof body === 'object' && 'data' in body) return body.data as T;
  return body as T;
}

export const getProducts = (query: URLSearchParams) => publicGet<ProductPage>(`/products?${query.toString()}`);
export const getProduct = (id: string) => publicGet<{ product: ProductSummary }>(`/products/${encodeURIComponent(id)}`);
export const getCategories = () => publicGet<{ categories: Category[] }>('/categories');
