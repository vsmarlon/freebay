import type { ProductPage } from './types';

export type CatalogFilters = { q: string; categoryId: string; minPrice: string; maxPrice: string; condition: string; sort: string; cursor?: string };
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
  return { products: [...current.products, ...next.products.filter((product) => !seen.has(product.id))], nextCursor: next.nextCursor };
}
