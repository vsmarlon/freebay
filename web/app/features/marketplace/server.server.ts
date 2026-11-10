import type { ProductPage, ProductSummary, Category } from './types';
import { toProductSummary } from './types';
import { ApiError } from '../../core/api';

function backendOrigin() {
  const origin = process.env.BACKEND_URL;
  if (!origin) throw new Error('BACKEND_URL is not configured for public marketplace SSR');
  return origin.replace(/\/$/, '');
}

async function publicGet<T>(path: string): Promise<T> {
  const response = await fetch(`${backendOrigin()}${path}`, {
    headers: { Accept: 'application/json' },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new ApiError('Marketplace request failed', response.status);
  const body: unknown = await response.json();
  if (body && typeof body === 'object' && 'data' in body) return body.data as T;
  return body as T;
}

export const getProducts = async (query: URLSearchParams): Promise<ProductPage> => {
  const page = await publicGet<ProductPage>(`/products?${query.toString()}`);
  return { products: page.products.map(toProductSummary), nextCursor: page.nextCursor };
};
export const getProduct = async (id: string): Promise<{ product: ProductSummary }> => {
  const data = await publicGet<{ product: ProductSummary }>(`/products/${encodeURIComponent(id)}`);
  return { product: toProductSummary(data.product) };
};
export const getCategories = () => publicGet<{ categories: Category[] }>('/categories');
