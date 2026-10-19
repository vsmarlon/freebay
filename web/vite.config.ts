import { reactRouter } from '@react-router/dev/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [tailwindcss(), reactRouter()],
  server: {
    proxy: Object.fromEntries(
      ['/auth', '/users', '/products', '/categories', '/social', '/stories', '/cart', '/orders', '/favorites', '/payments', '/wallet', '/reviews', '/disputes', '/chat', '/notifications', '/uploads', '/media', '/reports', '/bug-reports', '/health', '/socket.io'].map((path) => [path, {
        target: process.env.BACKEND_URL ?? 'http://localhost:3000',
        ws: path === '/socket.io',
        bypass: (request) => path === '/socket.io' || request.headers['x-freebay-api'] === '1' ? undefined : request.url,
      }]),
    ),
  },
});
