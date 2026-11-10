import { createServer } from 'node:http';

// DTO-shaped synthetic responses for public SSR only; never represents DB/provider evidence.
const product = {
  id: 'web-fixture-camera',
  title: 'Câmera analógica',
  description: 'Câmera em ótimo estado, testada e pronta para uso.',
  price: 10000,
  condition: 'USED',
  categoryId: 'photo',
  sellerId: '20000000-0000-4000-8000-000000000002',
  status: 'ACTIVE',
  quantity: 3,
  soldCount: 0,
  createdAt: '2026-10-01T12:00:00.000Z',
  seller: {
    id: '20000000-0000-4000-8000-000000000002',
    displayName: 'Pessoa de teste',
    isVerified: true,
    city: 'São Paulo',
    state: 'SP',
  },
  images: [{ id: 'image-fixture', url: 'https://images.example.invalid/camera.jpg', order: 0 }],
};
const send = (res, data) => {
  res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ data }));
};
const ssrObservations = [];

createServer((req, res) => {
  const url = new URL(req.url ?? '/', 'http://127.0.0.1:3333');
  if (url.pathname === '/health') return send(res, { status: 'ok' });
  if (url.pathname === '/__test/ssr-observations') return send(res, ssrObservations.splice(0));
  if (url.pathname.startsWith('/products') || url.pathname === '/categories')
    ssrObservations.push({
      path: url.pathname,
      hasAuthorization: Boolean(req.headers.authorization),
      hasCookie: Boolean(req.headers.cookie),
    });
  if (url.pathname === '/products' && req.method === 'GET')
    return send(res, { products: [product], nextCursor: null });
  if (url.pathname === `/products/${product.id}` && req.method === 'GET')
    return send(res, { product });
  if (url.pathname === '/categories' && req.method === 'GET')
    return send(res, {
      categories: [{ id: 'photo', name: 'Fotografia', parentId: null, children: [] }],
    });
  res.writeHead(404, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ message: `Fixture has no route for ${req.method} ${url.pathname}` }));
}).listen(Number(process.env.PORT ?? 3333), '127.0.0.1');
