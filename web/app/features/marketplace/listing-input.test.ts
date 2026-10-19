import { describe, expect, it } from 'vitest';
import { formatListingPriceInput, parseListingPrice, validateProductImage } from './listing-input';

describe('listing input boundaries', () => {
  it('accepts only supported image MIME types up to the backend 5 MB limit', () => {
    expect(validateProductImage({ type: 'image/webp', size: 5 * 1024 * 1024 })).toBeNull();
    expect(validateProductImage({ type: 'image/svg+xml', size: 10 })).toBe('type');
    expect(validateProductImage({ type: 'image/png', size: 5 * 1024 * 1024 + 1 })).toBe('size');
    expect(validateProductImage(null)).toBe('required');
  });

  it('converts valid currency text to integer cents and rejects zero, negative, and excess precision', () => {
    expect(parseListingPrice('R$ 1.234,50', 'pt-BR')).toBe(123450);
    expect(parseListingPrice('1,234.50', 'en')).toBe(123450);
    expect(parseListingPrice('0', 'pt-BR', true)).toBe(0);
    for (const value of ['0', '-1,00', '1,001', 'not money']) expect(() => parseListingPrice(value, 'pt-BR')).toThrow(TypeError);
  });

  it('seeds an edit price in the selected locale and round-trips the stored cents', () => {
    const field = formatListingPriceInput(1250, 'pt-BR');
    expect(field).toBe('12,50');
    expect(parseListingPrice(field, 'pt-BR')).toBe(1250);
  });
});
