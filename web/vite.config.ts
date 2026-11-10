import { reactRouter } from '@react-router/dev/vite';
import tailwindcss from '@tailwindcss/vite';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { transformSync } from 'oxc-transform-react';
import { defineConfig, loadEnv, type Plugin, type ProxyOptions } from 'vite';

// ponytail: content-hash cache, no eviction — Vite re-transforms the same route modules
// once per environment and on every rebuild; delete node_modules/.cache if it ever lies.
const compilerCache = join(process.cwd(), 'node_modules/.cache/freebay-react-compiler');
type CompilerMap = NonNullable<ReturnType<typeof transformSync>['map']>;
type CachedTransform = { code: string; map?: CompilerMap };

// JSON.parse is untyped; this guard is the contract with the writer below. The map
// cast is unavoidable: the compiler's shape is only known through its types.
function cachedTransform(value: unknown): CachedTransform | null {
  if (!value || typeof value !== 'object' || !('code' in value) || typeof value.code !== 'string')
    return null;
  const map = 'map' in value ? value.map : undefined;
  if (map !== undefined && map !== null && typeof map !== 'object') return null;
  return map ? { code: value.code, map: map as CompilerMap } : { code: value.code };
}

// React Compiler memoizes components and hooks; manual useCallback/useMemo is only
// kept where an effect dependency needs a stable identity. The Rust port (Oxc) is
// ~8x faster than the Babel plugin; JSX stays intact for the React Router transform.
const reactCompiler: Plugin = {
  name: 'react-compiler',
  enforce: 'pre',
  // SSR renders once per request; memoization only pays off in the browser bundle.
  applyToEnvironment: (environment) => environment.name !== 'ssr',
  transform(code, id) {
    if (!/[\\/]app[\\/].*\.tsx?$/.test(id)) return;
    const key = createHash('sha1').update(id).update('\0').update(code).digest('hex');
    const cachedPath = join(compilerCache, `${key}.json`);
    if (existsSync(cachedPath)) {
      try {
        const cached = cachedTransform(JSON.parse(readFileSync(cachedPath, 'utf8')));
        if (cached) return { code: cached.code, map: cached.map ?? null };
      } catch {
        /* corrupt entry falls through to a fresh transform */
      }
    }
    const result = transformSync(id, code, {
      jsx: 'preserve',
      sourcemap: true,
      reactCompiler: { target: '19' },
    });
    if (result.fatal || result.errors.length)
      throw new Error(`React Compiler failed on ${id}: ${JSON.stringify(result.errors)}`);
    const map = result.map ?? null;
    try {
      mkdirSync(compilerCache, { recursive: true });
      writeFileSync(cachedPath, JSON.stringify({ code: result.code, map }));
    } catch {
      /* cache is an optimization; a read-only tree still builds */
    }
    return { code: result.code, map };
  },
};

// ponytail: SSR (server.server.ts) reads process.env.BACKEND_URL at request time; dev never populates it from .env files, so seed it here. Shell env wins, then .env files, then the dev proxy default.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const backend = process.env.BACKEND_URL ?? env.BACKEND_URL ?? 'http://localhost:3000';
  process.env.BACKEND_URL ??= backend;

  // ponytail: socket teardown aborts during page unload are expected proxy noise; journeys still pass.
  const socketProxy: ProxyOptions = {
    target: backend,
    ws: true,
  };

  return {
    plugins: [tailwindcss(), reactRouter(), reactCompiler],
    // ponytail: pins dev-server prebundle discovery; without it the first socket use triggers a mid-session reload in dev (and in fixture journeys).
    optimizeDeps: { include: ['@tanstack/react-query', 'socket.io-client'] },
    server: {
      proxy: Object.fromEntries([
        ...(['/auth', '/users', '/products', '/categories', '/social', '/stories', '/cart', '/orders', '/favorites', '/payments', '/wallet', '/reviews', '/disputes', '/chat', '/notifications', '/uploads', '/media', '/reports', '/bug-reports', '/health'] as const).map((path) => [path, {
          target: backend,
          // ponytail: GIS redirect login POSTs natively (origin accounts.google.com, no header) — always forward it, otherwise the RR CSRF check aborts it.
        // ponytail: only page navigations stay on the RR dev server; media subresources (<img>/<video>/fonts under these prefixes) proxy through, else /uploads/* would return the SPA shell instead of the file.
        bypass: (request: import('http').IncomingMessage) => request.headers['x-freebay-api'] === '1' || request.url?.startsWith('/auth/web/google/redirect') || request.headers['sec-fetch-dest'] !== 'document' ? undefined : request.url,
        } satisfies ProxyOptions]),
        ['/socket.io', socketProxy] as const,
      ]),
    },
  };
});
