import { reactRouter } from '@react-router/dev/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig, loadEnv, type ProxyOptions } from 'vite';

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
    plugins: [tailwindcss(), reactRouter()],
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
