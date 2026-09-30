import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { AppModule } from '../../src/app.module';
import { StripeProvider } from '../../src/modules/payments/providers/stripe-provider';
import { StoryCleanupTask } from '../../src/modules/tasks/story-cleanup.task';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

interface ResponseBody {
  success: boolean;
  data: Record<string, unknown>;
  error?: { code: string };
}

describe('Story highlights (HTTP + real database)', () => {
  let app: INestApplication;
  let baseUrl: string;
  const suffix = Date.now().toString(36);

  async function call(method: string, path: string, token?: string, body?: object) {
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: response.status, json: await response.json() as ResponseBody };
  }

  beforeAll(async () => {
    assertSafeTestEnvironment();
    await prisma.$connect();
    await cleanDatabase(prisma);
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StripeProvider).useValue({}).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') throw new Error('No HTTP port');
    baseUrl = `http://127.0.0.1:${address.port}`;
  }, 120000);

  afterAll(async () => {
    await app?.close();
    await cleanDatabase(prisma);
    await prisma.$disconnect();
    await pool.end();
  });

  it('keeps expired stories private and publishes only selected stories with the chosen cover', async () => {
    const owner = await call('POST', '/auth/register', undefined, {
      displayName: 'Owner', username: `owner_${suffix}`.slice(0, 20),
      email: `owner-${suffix}@example.com`, password: 'password123',
    });
    const stranger = await call('POST', '/auth/register', undefined, {
      displayName: 'Stranger', username: `stranger_${suffix}`.slice(0, 20),
      email: `stranger-${suffix}@example.com`, password: 'password123',
    });
    expect(owner.status).toBe(201);
    expect(stranger.status).toBe(201);
    const ownerId = (owner.json.data.user as { id: string }).id;
    const ownerToken = owner.json.data.token as string;
    const strangerId = (stranger.json.data.user as { id: string }).id;
    const strangerToken = stranger.json.data.token as string;
    const [first, cover, foreign] = await Promise.all([
      prisma.story.create({ data: { userId: ownerId, imageUrl: '/uploads/one.jpg', expiresAt: new Date(2020, 0, 1) } }),
      prisma.story.create({ data: { userId: ownerId, imageUrl: '/uploads/cover.jpg', expiresAt: new Date(2020, 0, 1) } }),
      prisma.story.create({ data: { userId: strangerId, imageUrl: '/uploads/private.jpg', expiresAt: new Date(2020, 0, 1) } }),
    ]);

    const archive = await call('GET', '/stories/archive', ownerToken);
    expect(archive.status).toBe(200);
    expect((archive.json.data.stories as { id: string }[]).map((story) => story.id)).toEqual(expect.arrayContaining([first.id, cover.id]));
    expect((archive.json.data.stories as { id: string }[]).map((story) => story.id)).not.toContain(foreign.id);

    const denied = await call('POST', '/stories/highlights', ownerToken, {
      title: 'Invasão', storyIds: [foreign.id], coverStoryId: foreign.id,
    });
    expect(denied.status).toBe(400);

    const created = await call('POST', '/stories/highlights', ownerToken, {
      title: 'Viagens', storyIds: [first.id, cover.id], coverStoryId: cover.id,
    });
    expect(created.status).toBe(201);
    const highlightId = created.json.data.id as string;
    const publicList = await call('GET', `/stories/highlights/user/${ownerId}`, strangerToken);
    expect(publicList.status).toBe(200);
    const items = publicList.json.data.highlights as { title: string; coverUrl: string; stories: { id: string }[] }[];
    expect(items).toHaveLength(1);
    expect(items[0].title).toBe('Viagens');
    expect(items[0].coverUrl).toBe('/uploads/cover.jpg');
    expect(items[0].stories.map((story) => story.id)).toEqual([first.id, cover.id]);
    expect((await call('GET', '/stories/archive', strangerToken)).json.data.stories).toEqual([expect.objectContaining({ id: foreign.id })]);
    expect((await call('GET', `/stories/highlights/${highlightId}`, strangerToken)).status).toBe(200);
    expect((await call('PATCH', `/stories/highlights/${highlightId}`, strangerToken, {
      title: 'No', storyIds: [foreign.id], coverStoryId: foreign.id,
    })).status).toBe(403);

    await app.get(StoryCleanupTask).cleanupExpiredStories();
    expect((await call('GET', '/stories/archive', ownerToken)).json.data.stories).toEqual(expect.arrayContaining([
      expect.objectContaining({ id: first.id }), expect.objectContaining({ id: cover.id }),
    ]));
    expect((await call('GET', `/stories/highlights/${highlightId}`, strangerToken)).status).toBe(200);
  }, 120000);
});
