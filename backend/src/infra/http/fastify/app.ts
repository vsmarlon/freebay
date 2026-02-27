import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyHelmet from '@fastify/helmet';

import { env } from '@/env';

// Routes
import { authRoutes } from '../routes/auth.routes';
import { userRoutes } from '../routes/user.routes';
import { productRoutes } from '../routes/product.routes';
import { orderRoutes } from '../routes/order.routes';
import { socialRoutes } from '../routes/social.routes';
import { walletRoutes } from '../routes/wallet.routes';
import { paymentRoutes } from '../routes/payment.routes';
import { disputeRoutes } from '../routes/dispute.routes';
import { categoryRoutes } from '../routes/category.routes';
import { chatRoutes } from '../routes/chat.routes';

// Middlewares

export const app = Fastify({
  logger: {
    level: env.NODE_ENV === 'production' ? 'info' : 'debug',
    transport:
      env.NODE_ENV !== 'production'
        ? {
            target: 'pino-pretty',
            options: {
              colorize: true,
              translateTime: 'HH:MM:ss Z',
              ignore: 'pid,hostname',
            },
          }
        : undefined,
  },
});

// ─── Request logging hook ────────────────────────────────

app.addHook('onRequest', async (request) => {
  request.log.info({ url: request.url, method: request.method }, '→ incoming request');
});

app.addHook('onResponse', async (request, reply) => {
  request.log.info(
    { url: request.url, method: request.method, statusCode: reply.statusCode },
    '← response sent',
  );
});

app.addHook('onError', async (request, reply, error) => {
  request.log.error(
    { url: request.url, method: request.method, error: error.message },
    '❌ request error',
  );
});

// ─── Plugins ────────────────────────────────────────────

app.register(fastifyHelmet);
app.register(fastifyCors, {
  origin: env.ALLOWED_ORIGINS.split(','),
});
app.register(fastifyJwt, {
  secret: env.JWT_SECRET,
});

// ─── Routes ─────────────────────────────────────────────

app.register(authRoutes, { prefix: '/auth' });
app.register(userRoutes, { prefix: '/users' });
app.register(productRoutes, { prefix: '/products' });
app.register(orderRoutes, { prefix: '/orders' });
app.register(socialRoutes, { prefix: '/social' });
app.register(walletRoutes, { prefix: '/wallet' });
app.register(paymentRoutes, { prefix: '/payments' });
app.register(disputeRoutes, { prefix: '/disputes' });
app.register(categoryRoutes, { prefix: '/categories' });
app.register(chatRoutes, { prefix: '/chat' });

// ─── Static files ────────────────────────────────────────

app.get<{ Params: { file: string } }>('/uploads/:file', async (request, reply) => {
  const { file } = request.params;
  const fs = await import('fs');
  const path = await import('path');

  const filePath = path.join(process.cwd(), 'uploads', file);

  if (fs.existsSync(filePath)) {
    const stream = fs.createReadStream(filePath);
    return reply.type('image/jpeg').send(stream);
  }

  return reply.code(404).send({ error: 'File not found' });
});

// ─── Health check ───────────────────────────────────────

app.get('/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});
