import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { request as httpRequest, IncomingMessage } from 'http';
import { Pool } from 'pg';
import { AppModule } from '../../src/app.module';
import { StripeProvider } from '../../src/modules/payments/providers/stripe-provider';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

interface ApiResponse {
  success?: boolean;
  data?: { token?: string };
  error?: { code: string; message: string };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function parseApiResponse(value: unknown): ApiResponse {
  if (!isRecord(value)) throw new Error('Expected API response object');

  const data = isRecord(value.data) && typeof value.data.token === 'string'
    ? { token: value.data.token }
    : undefined;
  const error = isRecord(value.error)
    && typeof value.error.code === 'string'
    && typeof value.error.message === 'string'
    ? { code: value.error.code, message: value.error.message }
    : undefined;

  return {
    ...(typeof value.success === 'boolean' ? { success: value.success } : {}),
    ...(data ? { data } : {}),
    ...(error ? { error } : {}),
  };
}

function tokenFrom(response: ApiResponse): string {
  const token = response.data?.token;
  if (!token) throw new Error('Registration response did not include a token');
  return token;
}

describe('Cart clear HTTP regression', () => {
  let app: INestApplication;
  const suffix = Date.now().toString(36);
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    allowExitOnIdle: true,
  });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

  const request = (
    method: 'POST' | 'PATCH',
    path: string,
    token?: string,
    body?: unknown,
  ): Promise<{ status: number; json: ApiResponse }> => {
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') {
      throw new Error('Test server did not bind');
    }
    return new Promise((resolve, reject) => {
      const headers: Record<string, string> = {};
      const payload = body === undefined ? undefined : Buffer.from(JSON.stringify(body));
      if (token) headers.Authorization = `Bearer ${token}`;
      if (payload) {
        headers['Content-Type'] = 'application/json';
        headers['Content-Length'] = String(payload.length);
      }
      const req = httpRequest(
        { hostname: '127.0.0.1', port: address.port, path, method, headers },
        (res: IncomingMessage) => {
          const chunks: Buffer[] = [];
          res.on('data', (chunk: Buffer) => chunks.push(chunk));
          res.on('end', () => {
            const text = Buffer.concat(chunks).toString('utf8');
            const parsed: unknown = text ? JSON.parse(text) : {};
            resolve({ status: res.statusCode ?? 0, json: parseApiResponse(parsed) });
          });
          res.on('error', reject);
        },
      );
      req.on('error', reject);
      if (payload) req.write(payload);
      req.end();
    });
  };

  beforeAll(async () => {
    assertSafeTestEnvironment();
    await prisma.$connect();
    await cleanDatabase(prisma);
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StripeProvider)
      .useValue({})
      .compile();
    app = module.createNestApplication();
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);
  }, 120000);

  afterAll(async () => {
    await app?.close();
    await prisma.$disconnect();
    await pool.end();
  });

  it('clears only the authenticated cart with an empty PATCH body and preserves quantity validation', async () => {
    const [ownerRegistration, otherRegistration] = await Promise.all([
      request('POST', '/auth/register', undefined, {
        displayName: 'Cart Owner',
        username: `cart_owner_${suffix}`.slice(0, 20),
        email: `cart-owner-${suffix}@example.com`,
        password: 'password123',
      }),
      request('POST', '/auth/register', undefined, {
        displayName: 'Other Owner',
        username: `cart_other_${suffix}`.slice(0, 20),
        email: `cart-other-${suffix}@example.com`,
        password: 'password123',
      }),
    ]);
    expect(ownerRegistration.status).toBe(201);
    expect(otherRegistration.status).toBe(201);
    const ownerToken = tokenFrom(ownerRegistration.json);
    const otherToken = tokenFrom(otherRegistration.json);

    const owner = await prisma.user.findUniqueOrThrow({
      where: { email: `cart-owner-${suffix}@example.com` },
    });
    const other = await prisma.user.findUniqueOrThrow({
      where: { email: `cart-other-${suffix}@example.com` },
    });
    const category = await prisma.category.create({
      data: { name: `Cart ${suffix}`, slug: `cart-${suffix}` },
    });
    const product = await prisma.product.create({
      data: {
        sellerId: other.id,
        categoryId: category.id,
        title: 'Cart regression item',
        description: 'HTTP fixture',
        price: 1000,
        condition: 'USED',
        images: { create: { url: '/fixture.jpg' } },
      },
    });
    await prisma.cartItem.createMany({
      data: [
        { userId: owner.id, productId: product.id, quantity: 2 },
        { userId: other.id, productId: product.id, quantity: 3 },
      ],
    });

    const unauthorizedClear = await request('PATCH', '/cart/clear');
    expect(unauthorizedClear.status).toBe(401);
    expect(await prisma.cartItem.count()).toBe(2);

    const clear = await request('PATCH', '/cart/clear', ownerToken);
    expect(clear.status).toBe(200);
    expect(clear.json.success).toBe(true);
    expect(await prisma.cartItem.count({ where: { userId: owner.id } })).toBe(0);
    expect(await prisma.cartItem.count({ where: { userId: other.id } })).toBe(1);
    expect((await request('PATCH', '/cart/clear', ownerToken)).status).toBe(200);

    for (const quantity of [0, 11, 1.5]) {
      const invalidQuantity = await request('PATCH', `/cart/${product.id}`, otherToken, {
        quantity,
      });
      expect(invalidQuantity.status).toBe(400);
      expect(invalidQuantity.json.error?.code).toBe('VALIDATION_ERROR');
    }

    const quantityUpdate = await request('PATCH', `/cart/${product.id}`, otherToken, {
      quantity: 4,
    });
    expect(quantityUpdate.status).toBe(200);
    expect(await prisma.cartItem.findUniqueOrThrow({
      where: { userId_productId: { userId: other.id, productId: product.id } },
    })).toMatchObject({ quantity: 4 });
  });
});
