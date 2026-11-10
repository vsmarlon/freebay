import { request as httpRequest, createServer } from 'node:http';
import { request as httpsRequest } from 'node:https';
import { gzipSync } from 'node:zlib';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { createRequestListener } from '@react-router/node';
import * as build from './build/server/index.js';

const clientRoot = path.resolve('.', 'build', 'client');

const port = Number(process.env.PORT ?? 3001);
const backend = new URL(process.env.BACKEND_URL ?? 'http://localhost:3000');
const securityHeaders = {
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'strict-origin-when-cross-origin',
  'x-frame-options': 'DENY',
  'permissions-policy': 'camera=(), microphone=(), geolocation=(self)',
  'cross-origin-opener-policy': 'same-origin',
  'content-security-policy': "frame-ancestors 'none'; base-uri 'self'; object-src 'none'",
  ...(process.env.NODE_ENV === 'production'
    ? { 'strict-transport-security': 'max-age=31536000; includeSubDomains' }
    : {}),
};
const apiPrefixes = ['/auth', '/users', '/products', '/categories', '/social', '/stories', '/cart', '/orders', '/favorites', '/payments', '/wallet', '/reviews', '/disputes', '/chat', '/notifications', '/uploads', '/media', '/reports', '/bug-reports', '/health', '/socket.io'];
const isApiPath = (path) => apiPrefixes.some((prefix) => path === prefix || path.startsWith(`${prefix}/`));
const sendApp = createRequestListener({ build, mode: process.env.NODE_ENV ?? 'production' });
const sendAppNoCache = (incoming, outgoing) => {
  try {
    for (const [name, value] of Object.entries(securityHeaders)) outgoing.setHeader(name, value);
    outgoing.setHeader('cache-control', 'no-cache');
  } catch { /* ponytail: best-effort header, SSR handles missing ones */ }
  sendApp(incoming, outgoing);
};

// Static layer for build/client. ponytail: wasm brotli at build time would shave ~15% more bytes; streaming gzip covers the weak-internet floor.
const MIME = {
  '.js': 'text/javascript;charset=utf-8', '.css': 'text/css;charset=utf-8', '.json': 'application/json',
  '.html': 'text/html;charset=utf-8', '.txt': 'text/plain;charset=utf-8', '.map': 'application/json',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.ico': 'image/x-icon',
  '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf',
};
const COMPRESSIBLE = new Set(['.js', '.css', '.json', '.html', '.txt', '.map', '.svg']);
// ponytail: whole-client memory cache (~4 MB); swap for LRU if the build grows 100x.
const fileCache = new Map();

const serveStatic = async (incoming, outgoing) => {
  const pathname = decodeURIComponent((incoming.url ?? '/').split('?')[0]);
  if (pathname.includes('..') || pathname.includes('\0')) return false;
  const file = await (async () => {
    const target = path.resolve(clientRoot, pathname.replace(/^\/+/, ''));
    if (target !== clientRoot && !target.startsWith(clientRoot + path.sep)) return null;
    const hit = fileCache.get(target);
    if (hit) return hit;
    try {
      const info = await stat(target);
      if (!info.isFile()) return null;
      const raw = await readFile(target);
      const gz = COMPRESSIBLE.has(path.extname(target)) ? gzipSync(raw, { level: 6 }) : null;
      const entry = { raw, gz, type: MIME[path.extname(target)] ?? 'application/octet-stream' };
      fileCache.set(target, entry);
      return entry;
    } catch { return null; }
  })();
  if (!file) return false;
  const wantsGzip = Boolean(file.gz) && (incoming.headers['accept-encoding'] ?? '').includes('gzip');
  const body = wantsGzip ? file.gz : file.raw;
  const immutable = pathname.startsWith('/assets/');
  const head = {
    ...securityHeaders,
    'content-type': file.type,
    'content-length': body.length,
    'cache-control': immutable ? 'public, max-age=31536000, immutable' : 'no-cache',
    ...(wantsGzip ? { 'content-encoding': 'gzip', vary: 'accept-encoding' } : {}),
  };
  outgoing.writeHead(200, head);
  outgoing.end(incoming.method === 'HEAD' ? undefined : body);
  return true;
};

const server = createServer((incoming, outgoing) => {
  const path = new URL(incoming.url ?? '/', 'http://localhost').pathname;
  // GIS redirect login POSTs natively (origin accounts.google.com, no header) — always forward it, otherwise it lands in the React Router app.
  if (!isApiPath(path) || (path !== '/socket.io' && !path.startsWith('/socket.io/') && incoming.headers['x-freebay-api'] !== '1' && path !== '/auth/web/google/redirect')) {
    serveStatic(incoming, outgoing).then((served) => { if (!served && !outgoing.destroyed) sendAppNoCache(incoming, outgoing); });
    return;
  }
  const request = (backend.protocol === 'https:' ? httpsRequest : httpRequest)({
    protocol: backend.protocol, hostname: backend.hostname, port: backend.port,
    path: incoming.url ?? '/',
    method: incoming.method, headers: { ...incoming.headers, host: backend.host },
  }, (response) => {
    outgoing.writeHead(response.statusCode ?? 502, response.headers);
    response.pipe(outgoing);
  });
  request.on('error', () => { if (!outgoing.headersSent) outgoing.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' }); outgoing.end('Backend unavailable'); });
  incoming.pipe(request);
});
server.on('upgrade', (incoming, socket, head) => {
  const path = new URL(incoming.url ?? '/', 'http://localhost').pathname;
  if (!isApiPath(path)) { socket.destroy(); return; }
  const request = (backend.protocol === 'https:' ? httpsRequest : httpRequest)({
    protocol: backend.protocol, hostname: backend.hostname, port: backend.port,
    path: incoming.url, method: incoming.method, headers: { ...incoming.headers, host: backend.host },
  });
  request.on('upgrade', (response, upstream, upstreamHead) => {
    socket.write(`HTTP/1.1 ${response.statusCode} ${response.statusMessage}\r\n`);
    for (const [name, value] of Object.entries(response.headers)) socket.write(`${name}: ${Array.isArray(value) ? value.join(', ') : value}\r\n`);
    socket.write('\r\n');
    if (upstreamHead.length) socket.write(upstreamHead);
    if (head.length) upstream.write(head);
    upstream.pipe(socket); socket.pipe(upstream);
  });
  request.on('response', (response) => { socket.end(`HTTP/1.1 ${response.statusCode} ${response.statusMessage}\r\n\r\n`); });
  request.on('error', () => socket.destroy());
  request.end();
});
server.listen(port, () => console.log(`Freebay web listening on ${port}`));
