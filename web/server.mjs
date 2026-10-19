import { request as httpRequest, createServer } from 'node:http';
import { request as httpsRequest } from 'node:https';
import { createRequestListener } from '@react-router/node';
import * as build from './build/server/index.js';

const port = Number(process.env.PORT ?? 3001);
const backend = new URL(process.env.BACKEND_URL ?? 'http://localhost:3000');
const apiPrefixes = ['/auth', '/users', '/products', '/categories', '/social', '/stories', '/cart', '/orders', '/favorites', '/payments', '/wallet', '/reviews', '/disputes', '/chat', '/notifications', '/uploads', '/media', '/reports', '/bug-reports', '/health', '/socket.io'];
const isApiPath = (path) => apiPrefixes.some((prefix) => path === prefix || path.startsWith(`${prefix}/`));
const sendApp = createRequestListener({ build, mode: process.env.NODE_ENV ?? 'production' });
const server = createServer((incoming, outgoing) => {
  const path = new URL(incoming.url ?? '/', 'http://localhost').pathname;
  if (!isApiPath(path) || (path !== '/socket.io' && !path.startsWith('/socket.io/') && incoming.headers['x-freebay-api'] !== '1')) { sendApp(incoming, outgoing); return; }
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
