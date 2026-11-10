import { describe, expect, it } from 'vitest';
import { routeErrorKey } from './route-error-boundary';

const routeError = { status: 404, statusText: 'Not Found', internal: true, data: null };

describe('routeErrorKey', () => {
  it('uses the not-found key for a route error response', () => {
    expect(routeErrorKey(routeError, 'notFound', 'fallback')).toBe('notFound');
  });

  it('uses the fallback for a plain error', () => {
    expect(routeErrorKey(new Error('boom'), 'notFound', 'fallback')).toBe('fallback');
  });

  it('uses the fallback when the route has no not-found key', () => {
    expect(routeErrorKey(routeError, undefined, 'fallback')).toBe('fallback');
  });
});
