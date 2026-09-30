import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { request as httpRequest, IncomingMessage } from 'http';
import { rmSync } from 'fs';
import { join } from 'path';
import { Pool } from 'pg';
import { AppModule } from '../../src/app.module';
import { StripeProvider } from '../../src/modules/payments/providers/stripe-provider';
import { PaymentProviderError } from '../../src/shared/core/errors';
import { left, right } from '../../src/shared/core/either';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

// Full application over HTTP against the real test database: real guards,
// pipes, interceptors, usecases, and repositories. External networks are out
// of scope by construction — the journey never calls Stripe, FCM (disabled
// without credentials), or email providers.

interface ErrorBody {
  code: string;
  message: string;
}

interface Envelope {
  success: boolean;
  data?: Record<string, unknown>;
  error?: ErrorBody;
}

interface AuthData {
  user: { id: string; displayName: string };
  token: string;
  refreshToken: string;
}

// Single named place for response decoding: asserts the success envelope
// first, so a contract change fails loudly with the actual status.
function parseData<T extends object>(res: {
  status: number;
  json: Envelope;
}): T {
  expect(res.json.success).toBe(true);
  expect(res.json.data).toBeDefined();
  return res.json.data as T;
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  allowExitOnIdle: true,
});
const prisma = new PrismaClient({
  adapter: new PrismaPg(pool),
  log: ['error', 'warn'],
});

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

describe('Marketplace journey (HTTP + real database)', () => {
  let app: INestApplication;
  let port: number;
  const suffix = Date.now().toString(36);
  const createdUploads: string[] = [];
  let categoryId = '';
  let productId = '';
  let orderId = '';
  let sellerToken = '';
  let buyerToken = '';
  const stripe = { refundPayment: jest.fn(), cancelPendingPayment: jest.fn() };

  const http = (
    method: 'GET' | 'POST' | 'PATCH',
    path: string,
    options: { token?: string; body?: unknown; multipart?: { fields: Record<string, string>; file: Buffer } } = {},
  ): Promise<{ status: number; json: Envelope }> => {
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') {
      throw new Error('Test server did not bind to a port');
    }
    port = address.port;
    return new Promise((resolve, reject) => {
      const headers: Record<string, string> = {};
      let payload: Buffer | undefined;
      if (options.multipart) {
        const boundary = `e2e-${suffix}`;
        const parts: Buffer[] = [];
        for (const [name, value] of Object.entries(options.multipart.fields)) {
          parts.push(
            Buffer.from(
              `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`,
            ),
          );
        }
        parts.push(
          Buffer.from(
            `--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="product.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`,
          ),
        );
        parts.push(options.multipart.file);
        parts.push(Buffer.from(`\r\n--${boundary}--\r\n`));
        payload = Buffer.concat(parts);
        headers['Content-Type'] = `multipart/form-data; boundary=${boundary}`;
      } else if (options.body !== undefined) {
        payload = Buffer.from(JSON.stringify(options.body));
        headers['Content-Type'] = 'application/json';
      }
      if (options.token) headers.Authorization = `Bearer ${options.token}`;
      if (payload) headers['Content-Length'] = String(payload.length);
      const req = httpRequest(
        { hostname: '127.0.0.1', port, path, method, headers },
        (res: IncomingMessage) => {
          const chunks: Buffer[] = [];
          res.on('data', (chunk: Buffer) => chunks.push(chunk));
          res.on('end', () => {
            const text = Buffer.concat(chunks).toString('utf8');
            resolve({
              status: res.statusCode ?? 0,
              json: (text ? JSON.parse(text) : {}) as Envelope,
            });
          });
          res.on('error', reject);
        },
      );
      req.on('error', reject);
      if (payload) req.write(payload);
      req.end();
    });
  };

  const post = (
    path: string,
    options?: { token?: string; body?: unknown; multipart?: { fields: Record<string, string>; file: Buffer } },
  ): Promise<{ status: number; json: Envelope }> =>
    http('POST', path, options).then(async (res) => {
      await sleep(150);
      return res;
    });

  const get = (path: string, token?: string): Promise<{ status: number; json: Envelope }> =>
    http('GET', path, { token }).then(async (res) => {
      await sleep(150);
      return res;
    });

  const patch = (
    path: string,
    token: string,
    body: unknown,
  ): Promise<{ status: number; json: Envelope }> =>
    http('PATCH', path, { token, body }).then(async (res) => {
      await sleep(150);
      return res;
    });

  beforeAll(async () => {
    assertSafeTestEnvironment();
    await prisma.$connect();
    await cleanDatabase(prisma);

    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StripeProvider).useValue(stripe).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);

    const category = await prisma.category.create({
      data: { name: 'E2E Category', slug: `e2e-${suffix}` },
    });
    categoryId = category.id;
  }, 120000);

  afterAll(async () => {
    for (const url of createdUploads) {
      rmSync(join(process.cwd(), url.replace('/uploads/', 'uploads/')), { force: true });
    }
    await app?.close();
    await prisma.$disconnect();
    await pool.end();
  });

  it('registers a seller and a buyer with usable sessions', async () => {
    const seller = await post('/auth/register', {
      body: {
        displayName: 'E2E Seller',
        username: `e2e_seller_${suffix}`.slice(0, 20),
        email: `e2e-seller-${suffix}@example.com`,
        password: 'password123',
      },
    });
    expect(seller.status).toBe(201);
    const sellerData = parseData<AuthData>(seller);
    expect(sellerData.user.displayName).toBe('E2E Seller');
    expect(typeof sellerData.user.id).toBe('string');
    expect(typeof sellerData.token).toBe('string');
    expect(typeof sellerData.refreshToken).toBe('string');
    sellerToken = sellerData.token;

    const buyer = await post('/auth/register', {
      body: {
        displayName: 'E2E Buyer',
        username: `e2e_buyer_${suffix}`.slice(0, 20),
        email: `e2e-buyer-${suffix}@example.com`,
        password: 'password123',
      },
    });
    expect(buyer.status).toBe(201);
    buyerToken = parseData<AuthData>(buyer).token;
  });

  it('offers available usernames when the requested handle is taken', async () => {
    const username = `lookup_${suffix}`.slice(0, 16);
    const before = await get(`/auth/username-available?u=${username}`);
    expect(before.status).toBe(200);
    expect(parseData<{ available: boolean }>(before).available).toBe(true);

    await prisma.user.create({
      data: { email: `lookup-${suffix}@example.com`, username, displayName: 'Existing' },
    });
    await prisma.user.create({
      data: { email: `lookup-reserved-${suffix}@example.com`, username: `${username}_1`, displayName: 'Reserved' },
    });

    const lookup = await get(`/auth/username-available?u=${username.toUpperCase()}`);
    expect(lookup.status).toBe(200);
    const result = parseData<{ available: boolean; suggestions: string[] }>(lookup);
    expect(result.available).toBe(false);
    expect(result.suggestions).toHaveLength(3);
    expect(new Set(result.suggestions).size).toBe(3);
    expect(result.suggestions).not.toContain(`${username}_1`);
    for (const suggestion of result.suggestions) {
      expect(suggestion).toMatch(/^[a-z0-9_]{3,20}$/);
      expect(await prisma.user.findUnique({ where: { username: suggestion } })).toBeNull();
    }

    const chosen = result.suggestions[0];
    const registration = await post('/auth/register', {
      body: {
        displayName: 'New User', username: chosen,
        email: `suggestion-${suffix}@example.com`, password: 'password123',
      },
    });
    expect(registration.status).toBe(201);
    const after = await get(`/auth/username-available?u=${chosen}`);
    expect(parseData<{ available: boolean }>(after).available).toBe(false);
  });

  it('rejects a duplicate email without enumerating state', async () => {
    const res = await post('/auth/register', {
      body: {
        displayName: 'Clone',
        username: `e2e_clone_${suffix}`.slice(0, 20),
        email: `e2e-seller-${suffix}@example.com`,
        password: 'password123',
      },
    });
    expect(res.status).toBe(409);
    expect(res.json.success).toBe(false);
    expect(res.json.error?.code).toBe('EMAIL_ALREADY_EXISTS');
  });

  it('rejects wrong credentials and accepts the buyer login', async () => {
    const wrong = await post('/auth/login', {
      body: { email: `e2e-buyer-${suffix}@example.com`, password: 'wrong-password' },
    });
    expect(wrong.status).toBe(401);
    expect(wrong.json.error?.code).toBe('INVALID_CREDENTIALS');

    const ok = await post('/auth/login', {
      body: { email: `e2e-buyer-${suffix}@example.com`, password: 'password123' },
    });
    expect(ok.status).toBe(200);
    buyerToken = parseData<AuthData>(ok).token;
  });

  it('requires authentication for product creation', async () => {
    const res = await post('/products', {
      body: {
        title: 'Ghost Product',
        description: 'No session may create this product',
        price: 1000,
        condition: 'USED',
        categoryId,
      },
    });
    expect(res.status).toBe(401);
  });

  it('creates a product with an uploaded image, preserving integer cents', async () => {
    const res = await post('/products', {
      token: sellerToken,
      multipart: {
        fields: {
          title: 'E2E Test Product',
          description: 'End to end marketplace journey product',
          price: '10990',
          condition: 'USED',
          categoryId,
        },
        file: Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46]),
      },
    });
    expect(res.status).toBe(201);
    const product = parseData<{
      id: string;
      price: number;
    }>(res);
    expect(product.price).toBe(10990);
    expect(typeof product.id).toBe('string');
    expect(product.id).not.toHaveLength(0);
    productId = product.id;
  });

  it('rejects an invalid product payload through the validation pipe', async () => {
    const res = await post('/products', {
      token: sellerToken,
      multipart: {
        fields: {
          title: 'E2E Test Product',
          description: 'End to end marketplace journey product',
          price: '-5',
          condition: 'USED',
          categoryId,
        },
        file: Buffer.from([0xff, 0xd8, 0xff, 0xe0]),
      },
    });
    expect(res.status).toBe(400);
    expect(res.json.error?.code).toBe('VALIDATION_ERROR');
  });

  it('creates an order holding escrow for the buyer', async () => {
    const res = await post('/orders', {
      token: buyerToken,
      body: { productId },
    });
    expect(res.status).toBe(201);
    const order = parseData<{
      id: string;
      buyerId: string;
      sellerId: string;
      amount: number;
      platformFee: number;
      sellerAmount: number;
      status: string;
      escrowStatus: string;
    }>(res);
    expect(order.amount).toBe(10990);
    expect(order.sellerAmount).toBe(order.amount - order.platformFee);
    expect(order.status).toBe('PENDING');
    expect(order.escrowStatus).toBe('HELD');
    orderId = order.id;
  });

  it('refuses a self-purchase by the seller', async () => {
    const res = await post('/orders', {
      token: sellerToken,
      body: { productId },
    });
    expect(res.status).toBe(400);
    expect(res.json.success).toBe(false);
  });

  it('lets the buyer read the order but forbids an outsider', async () => {
    const mine = await get(`/orders/${orderId}`, buyerToken);
    expect(mine.status).toBe(200);

    const outsider = await post('/auth/register', {
      body: {
        displayName: 'E2E Outsider',
        username: `e2e_out_${suffix}`.slice(0, 20),
        email: `e2e-outsider-${suffix}@example.com`,
        password: 'password123',
      },
    });
    const outsiderToken = parseData<AuthData>(outsider).token;
    const forbidden = await get(`/orders/${orderId}`, outsiderToken);
    expect(forbidden.status).toBe(403);
    expect(forbidden.json.error?.code).toBe('FORBIDDEN');
  });

  it('lists the order in the seller sales with pagination metadata', async () => {
    const res = await get('/orders/my/sales?limit=10', sellerToken);
    expect(res.status).toBe(200);
    const page = parseData<{
      items: Array<{ id: string }>;
      hasMore: boolean;
    }>(res);
    expect(page.items.map((item) => item.id)).toContain(orderId);
  });

  it('starts a buyer wallet at zero across every balance', async () => {
    const res = await get('/wallet', buyerToken);
    expect(res.status).toBe(200);
    const wallet = parseData<{
      balance: number;
      pendingBalance: number;
      availableBalance: number;
    }>(res);
    expect(wallet.balance).toBe(0);
    expect(wallet.pendingBalance).toBe(0);
    expect(wallet.availableBalance).toBe(0);
  });

  it('cancels the order with a reason and persists it', async () => {
    const res = await patch(`/orders/${orderId}/cancel`, buyerToken, {
      reason: 'E2E changed mind',
    });
    expect(res.status).toBe(200);
    expect(res.json.success).toBe(true);

    const stored = await prisma.order.findUnique({ where: { id: orderId } });
    expect(stored?.status).toBe('CANCELLED');
    expect(stored?.cancellationReason).toBe('E2E changed mind');
  });

  it('rejects a cancel without a reason before touching the order', async () => {
    const second = await post('/products', {
      token: sellerToken,
      multipart: {
        fields: {
          title: 'E2E Second Product',
          description: 'Second product for the cancel-reason journey',
          price: '5000',
          condition: 'NEW',
          categoryId,
        },
        file: Buffer.from([0xff, 0xd8, 0xff, 0xe0]),
      },
    });
    expect(second.status).toBe(201);
    const secondId = parseData<{ id: string }>(second).id;

    const order = await post('/orders', {
      token: buyerToken,
      body: { productId: secondId },
    });
    expect(order.status).toBe(201);
    const secondOrderId = parseData<{ id: string }>(order).id;

    const missing = await patch(`/orders/${secondOrderId}/cancel`, buyerToken, {});
    expect(missing.status).toBe(400);
    expect(missing.json.error?.code).toBe('VALIDATION_ERROR');

    const cancelled = await patch(`/orders/${secondOrderId}/cancel`, buyerToken, {
      reason: 'E2E changed mind',
    });
    expect(cancelled.status).toBe(200);
  });

  it('serves the public product page with the uploaded image and no session', async () => {
    const res = await get(`/products/${productId}`);
    expect(res.status).toBe(200);
    const detail = parseData<{
      product: { price: number; images: Array<{ url: string }> };
    }>(res).product;
    expect(detail.price).toBe(10990);
    expect(detail.images).toHaveLength(1);
    createdUploads.push(detail.images[0].url);
  });

  it('paginates own posts and reposts together in the profile timeline without losing text', async () => {
    const seller = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-seller-${suffix}@example.com` } });
    const buyer = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-buyer-${suffix}@example.com` } });
    const start = Date.now() + 86_400_000;
    const older = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: 'Text-only first', createdAt: new Date(start) } });
    const foreign = await prisma.post.create({ data: { userId: buyer.id, type: 'REGULAR', content: 'Reposted text', createdAt: new Date(start + 1000) } });
    await prisma.share.create({ data: { userId: seller.id, postId: foreign.id, createdAt: new Date(start + 5000) } });
    const latest = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: 'Text-only last', createdAt: new Date(start + 10000) } });

    const first = await get(`/social/posts/user/${seller.id}/timeline?limit=2`, sellerToken);
    expect(first.status).toBe(200);
    const page = parseData<{
      items: Array<{ post: { id: string; content: string; imageUrl: string | null }; isReposted: boolean; repostedBy: { id: string } | null }>;
      nextCursor: string | null;
      hasMore: boolean;
    }>(first);
    expect(page.items.map((entry) => entry.post.id)).toEqual([latest.id, foreign.id]);
    expect(page.items[0].post.imageUrl).toBeNull();
    expect(page.items[0].post.content).toBe('Text-only last');
    expect(page.items[1].isReposted).toBe(true);
    expect(page.items[1].repostedBy?.id).toBe(seller.id);
    expect(page.hasMore).toBe(true);

    const next = await get(`/social/posts/user/${seller.id}/timeline?limit=2&cursor=${encodeURIComponent(page.nextCursor!)}`, sellerToken);
    expect(next.status).toBe(200);
    const olderPage = parseData<{ items: Array<{ post: { id: string } }> }>(next);
    expect(olderPage.items[0].post.id).toBe(older.id);
    expect(olderPage.items.map((entry) => entry.post.id)).not.toContain(foreign.id);
  });

  it('rejects a reply whose parent belongs to a different post without changing counts', async () => {
    const seller = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-seller-${suffix}@example.com` } });
    const target = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: 'Reply target' } });
    const other = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: 'Other thread' } });
    const root = await post(`/social/posts/${other.id}/comments`, {
      token: sellerToken, body: { content: 'Root comment' },
    });
    expect(root.status).toBe(201);
    const parentId = parseData<{ id: string }>(root).id;

    const reply = await post(`/social/posts/${target.id}/comments`, {
      token: sellerToken, body: { content: 'Cross-post reply', parentId },
    });
    expect(reply.status).toBe(400);
    expect(await prisma.comment.count({ where: { postId: target.id } })).toBe(0);
    expect((await prisma.post.findUniqueOrThrow({ where: { id: target.id } })).commentsCount).toBe(0);
  });

  it('hides blocked accounts and their reposts across social reads in both directions', async () => {
    const seller = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-seller-${suffix}@example.com` } });
    const buyer = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-buyer-${suffix}@example.com` } });
    const marker = `blocked-social-${suffix}`;
    const sellerPost = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: marker } });
    const buyerPost = await prisma.post.create({ data: { userId: buyer.id, type: 'REGULAR', content: marker } });
    const sellerComment = await prisma.comment.create({ data: { userId: seller.id, postId: sellerPost.id, content: marker } });
    await prisma.share.createMany({ data: [
      { userId: buyer.id, postId: sellerPost.id },
      { userId: seller.id, postId: buyerPost.id },
    ] });

    const before = await get(`/social/posts/search?q=${marker}`, buyerToken);
    expect(before.status).toBe(200);
    expect(parseData<Array<{ id: string; hasReposted: boolean }>>(before))
      .toEqual(expect.arrayContaining([expect.objectContaining({ id: sellerPost.id, hasReposted: true })]));
    expect(parseData<Array<{ id: string }>>(await get(`/social/posts/${sellerPost.id}/comments`, buyerToken))).toHaveLength(1);

    expect((await post(`/users/${seller.id}/block`, { token: buyerToken })).status).toBe(200);

    for (const [viewerToken, hiddenPostId, hiddenOwnerId] of [
      [buyerToken, sellerPost.id, seller.id],
      [sellerToken, buyerPost.id, buyer.id],
    ]) {
      expect((await get(`/social/posts/${hiddenPostId}`, viewerToken)).status).toBe(404);
      const comments = await get(`/social/posts/${hiddenPostId}/comments`, viewerToken);
      expect(comments.status).toBe(200);
      expect(parseData<Array<{ id: string }>>(comments)).toHaveLength(0);
      for (const action of ['like', 'share', 'save']) {
        expect((await post(`/social/posts/${hiddenPostId}/${action}`, { token: viewerToken })).status).toBe(404);
      }
      expect((await post(`/social/posts/${hiddenPostId}/comments`, {
        token: viewerToken, body: { content: 'Blocked interaction' },
      })).status).toBe(404);
      const search = await get(`/social/posts/search?q=${marker}`, viewerToken);
      expect(search.status).toBe(200);
      expect(parseData<Array<{ id: string }>>(search).map((post) => post.id)).not.toContain(hiddenPostId);

      const ownPosts = await get(`/social/posts/user/${hiddenOwnerId}`, viewerToken);
      expect(ownPosts.status).toBe(200);
      expect(parseData<{ items: Array<{ post: { id: string } }> }>(ownPosts).items).toHaveLength(0);

      const timeline = await get(`/social/posts/user/${hiddenOwnerId}/timeline`, viewerToken);
      expect(timeline.status).toBe(200);
      expect(parseData<{ items: Array<{ post: { id: string } }> }>(timeline).items).toHaveLength(0);

      const reposts = await get(`/social/posts/user/${hiddenOwnerId}/reposts`, viewerToken);
      expect(reposts.status).toBe(200);
      expect(parseData<Array<{ post: { id: string } }>>(reposts)).toHaveLength(0);
    }

    const buyerReposts = await get(`/social/posts/user/${buyer.id}/reposts`, buyerToken);
    expect(buyerReposts.status).toBe(200);
    expect(parseData<Array<{ post: { id: string } }>>(buyerReposts).map((entry) => entry.post.id))
      .not.toContain(sellerPost.id);
    expect((await post(`/social/comments/${sellerComment.id}/like`, { token: buyerToken })).status).toBe(404);
    expect(await prisma.commentLike.count({ where: { userId: buyer.id, commentId: sellerComment.id } })).toBe(0);
    expect((await get(`/social/posts/${sellerPost.id}`)).status).toBe(200);
  });

  it('does not claim a paid order was refunded when Stripe rejects the refund, then settles without crediting a buyer wallet', async () => {
    const buyer = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-buyer-${suffix}@example.com` } });
    const seller = await prisma.user.findUniqueOrThrow({ where: { email: `e2e-seller-${suffix}@example.com` } });
    const order = await prisma.order.create({ data: {
      buyerId: buyer.id, sellerId: seller.id, productId,
      amount: 5000, platformFee: 500, sellerAmount: 4500,
      status: 'CONFIRMED', escrowStatus: 'HELD',
    } });
    await prisma.transaction.create({ data: {
      orderId: order.id, amount: 5000, platformFee: 500, sellerAmount: 4500,
      paymentMethod: 'CREDIT_CARD', provider: 'STRIPE', status: 'PAID',
      idempotencyKey: `${suffix}-refund`, externalId: 'pi_test_paid', chargeId: 'ch_test_paid',
    } });
    await prisma.wallet.upsert({ where: { userId: seller.id }, create: { userId: seller.id, pendingBalance: 4500 }, update: { pendingBalance: 4500 } });

    stripe.refundPayment.mockResolvedValueOnce(left(new PaymentProviderError('Refund failed')))
      .mockResolvedValueOnce(right('pending'))
      .mockResolvedValueOnce(right('succeeded'));
    const failed = await patch(`/orders/${order.id}/cancel`, buyerToken, { reason: 'Changed mind' });
    expect(failed.status).toBe(500);
    expect((await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).status).toBe('CONFIRMED');
    expect((await prisma.wallet.findUniqueOrThrow({ where: { userId: seller.id } })).pendingBalance).toBe(4500);
    expect((await prisma.wallet.findUniqueOrThrow({ where: { userId: buyer.id } })).availableBalance).toBe(0);

    const pending = await patch(`/orders/${order.id}/cancel`, buyerToken, { reason: 'Changed mind' });
    expect(pending.status).toBe(200);
    expect(pending.json.data).toBe('REFUND_PENDING');
    expect((await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).status).toBe('CONFIRMED');
    expect((await patch(`/orders/${order.id}/ship`, sellerToken, {})).status).toBe(422);

    const succeeded = await patch(`/orders/${order.id}/cancel`, buyerToken, { reason: 'Changed mind' });
    expect(succeeded.status).toBe(200);
    expect(stripe.refundPayment).toHaveBeenCalledTimes(3);
    expect((await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).status).toBe('CANCELLED');
    expect((await prisma.wallet.findUniqueOrThrow({ where: { userId: seller.id } })).pendingBalance).toBe(0);
    expect((await prisma.wallet.findUniqueOrThrow({ where: { userId: buyer.id } })).availableBalance).toBe(0);
    expect((await prisma.transaction.findUniqueOrThrow({ where: { orderId: order.id } })).status).toBe('REFUNDED');
  });
});
