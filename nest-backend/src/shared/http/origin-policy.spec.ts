import { isAllowedOrigin, parseAllowedOrigins } from './origin-policy';

describe('origin policy', () => {
  it('allows requests without Origin but rejects malformed, null, wildcard, and unlisted origins', () => {
    const allowed = parseAllowedOrigins('https://shop.example:8443');
    expect(isAllowedOrigin(undefined, allowed)).toBe(true);
    expect(isAllowedOrigin('https://shop.example:8443', allowed)).toBe(true);
    expect(isAllowedOrigin('https://shop.example', allowed)).toBe(false);
    expect(isAllowedOrigin('null', allowed)).toBe(false);
    expect(isAllowedOrigin('*', allowed)).toBe(false);
  });
});
