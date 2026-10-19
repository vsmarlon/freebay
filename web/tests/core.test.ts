import { describe, expect, it, vi } from 'vitest';
import { parseMoney, formatMoney } from '../app/core/money';
import { appPath, pathsFor, safeLocalizedReturnTo } from '../app/core/routes';
import { api, clearAccessToken } from '../app/core/api';
import { localizedCallbackLocation } from '../app/routes/legacy-callback';
import { completeOnboarding, completeWelcome, hasCompletedOnboarding, hasSeenWelcome } from '../app/core/session';
import { boundedImageSize, editedImageFile, rotatedImageSize, supportedEditorFile } from '../app/components/image-editor';

describe('money boundaries', () => {
  it('parses locale punctuation into exact integer cents', () => {
    expect(parseMoney('R$ 1.234,56')).toBe(123456);
    expect(parseMoney('1,234.56')).toBe(123456);
    expect(parseMoney('0,01')).toBe(1);
    expect(parseMoney('1.2')).toBe(120);
    expect(parseMoney('-1.02')).toBe(-102);
    expect(formatMoney(12500, 'pt-BR')).toContain('125,00');
  });
  it('rejects ambiguous or fractional-cent input', () => {
    expect(() => parseMoney('1,234,56')).toThrow(TypeError);
    expect(() => parseMoney('1,234')).toThrow(TypeError);
    expect(() => parseMoney('2R$ 1,00')).toThrow(TypeError);
  });
});

describe('locale routes', () => {
  it('prefixes routes and encodes dynamic identifiers', () => {
    expect(appPath('pt-BR', 'products/a b')).toBe('/pt-BR/products/a b');
    expect(pathsFor.onboarding).toBe('onboarding');
    expect(pathsFor.welcome).toBe('welcome');
    expect(pathsFor.peopleSearch).toBe('search/people');
    expect(pathsFor.myPosts).toBe('posts/mine');
    expect(pathsFor.product('id/with space')).toBe('products/id%2Fwith%20space');
    expect(pathsFor.conversation('a/b')).toBe('messages/a%2Fb');
    expect(pathsFor.highlights('person')).toBe('highlights/person');
  });
  it('localizes only configured provider callbacks and preserves their query', () => {
    expect(localizedCallbackLocation(new Request('https://freebay.example/payments/success?paymentGroupId=g', { headers: { 'accept-language': 'en-US,en;q=0.9' } }))).toBe('/en/payments/success?paymentGroupId=g');
    expect(localizedCallbackLocation(new Request('https://freebay.example/wallet/connect/return?state=opaque'))).toBe('/pt-BR/wallet?state=opaque');
    expect(() => localizedCallbackLocation(new Request('https://freebay.example/payment-success'))).toThrow(Response);
  });
});

describe('auth return destinations and first-run preferences', () => {
  it('keeps return destinations inside the current locale and avoids auth-route loops', () => {
    expect(safeLocalizedReturnTo('/en/orders/123?tab=active#detail', 'en')).toBe('/en/orders/123?tab=active#detail');
    for (const unsafe of ['https://attacker.example', '//attacker.example', '/pt-BR/feed', '/en/login', '/en/complete-profile', '/en/\\\\attacker']) {
      expect(safeLocalizedReturnTo(unsafe, 'en')).toBe('/en/feed');
    }
  });
  it('persists onboarding once and remembers welcome completion independently per account', () => {
    const saved = new Map<string, string>();
    vi.stubGlobal('localStorage', { getItem: (key: string) => saved.get(key) ?? null, setItem: (key: string, value: string) => { saved.set(key, value); } });
    expect(hasCompletedOnboarding()).toBe(false);
    completeOnboarding();
    expect(hasCompletedOnboarding()).toBe(true);
    expect(hasSeenWelcome('account-a')).toBe(false);
    completeWelcome('account-a');
    expect(hasSeenWelcome('account-a')).toBe(true);
    expect(hasSeenWelcome('account-b')).toBe(false);
    vi.unstubAllGlobals();
  });
});

describe('browser image editor bounds', () => {
  it('keeps decoded canvas dimensions under the working pixel limit', () => {
    expect(boundedImageSize(6000, 3000)).toEqual({ width: 2048, height: 1024 });
    expect(boundedImageSize(120, 80)).toEqual({ width: 120, height: 80 });
  });
  it('rejects invalid and pathological source dimensions before canvas allocation', () => {
    expect(() => boundedImageSize(0, 20)).toThrow(RangeError);
    expect(() => boundedImageSize(Number.NaN, 20)).toThrow(RangeError);
    expect(() => boundedImageSize(100_000, 100_000)).toThrow(RangeError);
  });
  it('allocates the full rotated output instead of clipping a quarter turn', () => {
    expect(rotatedImageSize(800, 400, 90)).toEqual({ width: 400, height: 800 });
    expect(rotatedImageSize(800, 400, 180)).toEqual({ width: 800, height: 400 });
    expect(rotatedImageSize(800, 400, -90)).toEqual({ width: 400, height: 800 });
    expect(rotatedImageSize(800, 400, 45)).toEqual({ width: 849, height: 849 });
    expect(Math.max(rotatedImageSize(2048, 2048, 45).width, rotatedImageSize(2048, 2048, 45).height)).toBeLessThanOrEqual(2048);
  });
  it('accepts bounded raster files and rejects empty, oversized, and SVG inputs', () => {
    expect(supportedEditorFile({ type: 'image/jpeg', size: 1000 })).toBe(true);
    expect(supportedEditorFile({ type: 'image/jpeg', size: 0 })).toBe(false);
    expect(supportedEditorFile({ type: 'image/svg+xml', size: 1000 })).toBe(false);
    expect(supportedEditorFile({ type: 'image/png', size: 32 * 1024 * 1024 + 1 })).toBe(false);
    expect(supportedEditorFile({ type: 'application/pdf', size: 1000 })).toBe(false);
  });
  it('returns the flattened PNG File shape for a successful canvas export and rejects failed exports', async () => {
    const output = editedImageFile(new Blob(['pixels'], { type: 'image/png' }), 'listing.jpg', 1234);
    expect(output).toBeInstanceOf(File);
    expect(output).toMatchObject({ name: 'listing-edited.png', type: 'image/png', lastModified: 1234, size: 6 });
    await expect(async () => editedImageFile(null, 'listing.png')).rejects.toThrow(TypeError);
  });
});

describe('browser API boundary', () => {
  it('refuses off-origin paths before exposing credentials', async () => {
    const fetcher = vi.fn(); vi.stubGlobal('fetch', fetcher); vi.stubGlobal('window', {}); vi.stubGlobal('location', { origin: 'http://localhost' });
    await expect(api.get('https://attacker.example/collect')).rejects.toThrow(TypeError);
    expect(fetcher).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
  it('does not retry an ambiguous write after authorization failure', async () => {
    clearAccessToken();
    const fetcher = vi.fn().mockResolvedValueOnce(new Response(JSON.stringify({ data: { token: 'access' } }), { status: 200 })).mockResolvedValueOnce(new Response(JSON.stringify({ message: 'expired' }), { status: 401 }));
    vi.stubGlobal('fetch', fetcher); vi.stubGlobal('window', {}); vi.stubGlobal('location', { origin: 'http://localhost' });
    await expect(api.post('/cart/items', { quantity: 1 })).rejects.toMatchObject({ status: 401 });
    expect(fetcher).toHaveBeenCalledTimes(2);
    expect(fetcher.mock.calls[0]?.[1]).toMatchObject({ method: 'POST', credentials: 'include', cache: 'no-store' });
    expect(fetcher.mock.calls[0]?.[1]).toMatchObject({ headers: { 'X-Freebay-API': '1' } });
    vi.unstubAllGlobals(); clearAccessToken();
  });
  it('preserves nested backend error messages and codes', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(JSON.stringify({ success: false, error: { code: 'ACCOUNT_LOCKED', message: 'Try later' } }), { status: 423 }))); vi.stubGlobal('window', {}); vi.stubGlobal('location', { origin: 'http://localhost' });
    await expect(api.get('/health', { auth: false })).rejects.toMatchObject({ status: 423, code: 'ACCOUNT_LOCKED', message: 'Try later' });
    vi.unstubAllGlobals();
  });
  it('rejects an in-flight response after the session is cleared', async () => {
    clearAccessToken();
    let finish!: (response: Response) => void;
    const fetcher = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ token: 'old-session' }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ data: { ok: true } }), { status: 200 }))
      .mockImplementationOnce(() => new Promise<Response>((resolve) => { finish = resolve; }));
    vi.stubGlobal('fetch', fetcher); vi.stubGlobal('window', {}); vi.stubGlobal('location', { origin: 'http://localhost' });
    await api.get('/warm');
    const request = api.get('/users/me');
    await Promise.resolve();
    clearAccessToken(); finish(new Response(JSON.stringify({ id: 'old-user', displayName: 'Old user' }), { status: 200 }));
    await expect(request).rejects.toMatchObject({ status: 401 });
    vi.unstubAllGlobals(); clearAccessToken();
  });
  it('refreshes cookies before exchanging an expired access cookie for a bearer', async () => {
    clearAccessToken();
    const fetcher = vi.fn()
      .mockResolvedValueOnce(new Response(null, { status: 401 }))
      .mockResolvedValueOnce(new Response('refresh response is ignored', { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ token: 'fresh-access' }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ data: { ok: true } }), { status: 200 }));
    vi.stubGlobal('fetch', fetcher); vi.stubGlobal('window', {}); vi.stubGlobal('location', { origin: 'http://localhost' });
    await expect(api.get('/users/me')).resolves.toEqual({ ok: true });
    expect(fetcher.mock.calls.map(([url]) => url)).toEqual(['/auth/web/session/access-token', '/auth/web/session/refresh', '/auth/web/session/access-token', '/users/me']);
    expect(fetcher.mock.calls[0]?.[1]).toMatchObject({ method: 'POST', credentials: 'include' });
    expect(fetcher.mock.calls[0]?.[1]).toMatchObject({ headers: { 'X-Freebay-API': '1' } });
    expect(fetcher.mock.calls[1]?.[1]).toMatchObject({ method: 'POST', credentials: 'include' });
    expect(fetcher.mock.calls[2]?.[1]).toMatchObject({ method: 'POST', credentials: 'include' });
    vi.unstubAllGlobals(); clearAccessToken();
  });
});
