import { describe, expect, it } from 'vitest';
import { appendPage, catalogQuery, parseCentsFilter } from './queries';
import { formatListingPriceInput, parseListingPrice } from './listing-input';

describe('catalog query contract', () => {
  it('maps visible search and filters to backend field names and integer cents', () => {
    const query = catalogQuery({
      q: '  lamp  ',
      categoryId: 'category-1',
      minPrice: '1250',
      maxPrice: '50000',
      condition: 'USED',
      sort: 'price_asc',
    });
    expect(Object.fromEntries(query)).toEqual({
      limit: '20',
      search: 'lamp',
      category: 'category-1',
      minPrice: '1250',
      maxPrice: '50000',
      condition: 'USED',
      sort: 'price_asc',
    });
  });

  it('rejects fractional or unsafe cent values rather than silently rounding', () => {
    expect(() => parseCentsFilter('12.5')).toThrow(TypeError);
    expect(() => parseCentsFilter(String(Number.MAX_SAFE_INTEGER + 1))).toThrow(TypeError);
  });

  it('retains a seeded PT-BR cents filter through edit/display/submit mapping', () => {
    const displayValue = formatListingPriceInput(1250, 'pt-BR');
    const submittedCents = parseListingPrice(displayValue, 'pt-BR', true);
    const query = catalogQuery({
      q: '',
      categoryId: '',
      minPrice: String(submittedCents),
      maxPrice: '',
      condition: '',
      sort: 'recent',
    });
    expect(displayValue).toBe('12,50');
    expect(query.get('minPrice')).toBe('1250');
  });

  it('appends cursor pages without duplicating the boundary item', () => {
    const product = (id: string) => ({
      id,
      title: id,
      price: 1,
      description: '',
      condition: 'USED' as const,
      categoryId: '',
      sellerId: '',
      status: 'ACTIVE' as const,
      quantity: 1,
      soldCount: 0,
      createdAt: '',
      seller: { id: '', displayName: '' },
      images: [],
    });
    expect(
      appendPage(
        { products: [product('a'), product('b')], nextCursor: 'b' },
        { products: [product('b'), product('c')], nextCursor: null },
      ),
    ).toEqual({ products: [product('a'), product('b'), product('c')], nextCursor: null });
  });
});
