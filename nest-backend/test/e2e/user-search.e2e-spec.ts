import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import type { Express } from 'express';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/shared/infra/prisma/prisma.service';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });
type SearchUser = { id: string; username: string | null; displayName: string };
type SearchBody = { data: { users: SearchUser[]; hasMore: boolean; nextOffset: number | null } };
type RegisterBody = { data: { user: { id: string }; token: string } };

function isSearchBody(value: unknown): value is SearchBody {
  if (typeof value !== 'object' || value === null || !('data' in value) || typeof value.data !== 'object' || value.data === null || !('users' in value.data) || !Array.isArray(value.data.users)) return false;
  return value.data.users.every((user: unknown) => typeof user === 'object' && user !== null && 'id' in user && typeof user.id === 'string' && 'displayName' in user && typeof user.displayName === 'string' && 'username' in user && (typeof user.username === 'string' || user.username === null));
}

function isRegisterBody(value: unknown): value is RegisterBody {
  return typeof value === 'object' && value !== null && 'data' in value && typeof value.data === 'object' && value.data !== null && 'user' in value.data && typeof value.data.user === 'object' && value.data.user !== null && 'id' in value.data.user && typeof value.data.user.id === 'string' && 'token' in value.data && typeof value.data.token === 'string';
}

describe('User search (HTTP + real database)', () => {
  let app: INestApplication | undefined;
  let baseUrl: string;
  let token: string;
  let viewerId: string;
  let rankIds: string[];
  let exactUsernameId: string;
  let prefixUsernameId: string;
  let prismaInit: jest.SpyInstance;
  let prismaDestroy: jest.SpyInstance;
  let testCaseNumber = 0;
  const suffix = Date.now().toString(36);
  const call = async (path: string) => {
    const response = await fetch(`${baseUrl}${path}`, { headers: { Authorization: `Bearer ${token}`, 'X-Forwarded-For': `198.51.100.${++testCaseNumber}` } });
    const body: unknown = await response.json();
    if (!isSearchBody(body)) throw new Error('Unexpected user-search response');
    return { status: response.status, body };
  };
  const register = async (displayName: string, username: string) => {
    const response = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': `198.51.100.${++testCaseNumber}` },
      body: JSON.stringify({ displayName, username: `${username}_${suffix}`.slice(0, 20), email: `${username}-${suffix}@example.com`, password: 'password123' }),
    });
    expect(response.status).toBe(201);
    const body: unknown = await response.json();
    if (!isRegisterBody(body)) throw new Error('Unexpected registration response');
    return body;
  };

  beforeAll(async () => {
    assertSafeTestEnvironment();
    prismaInit = jest.spyOn(PrismaService.prototype, 'onModuleInit');
    prismaDestroy = jest.spyOn(PrismaService.prototype, 'onModuleDestroy');
    await prisma.$connect();
    await cleanDatabase(prisma);
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = module.createNestApplication();
    const expressApp: Express = app.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', 'loopback');
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);
    const address = app.getHttpServer().address();
    if (!address || typeof address === 'string') throw new Error('No HTTP port');
    baseUrl = `http://127.0.0.1:${address.port}`;
    const viewer = await register('Search Viewer', 'viewer');
    token = viewer.data.token;
    viewerId = viewer.data.user.id;
    await register('Ana Silva', 'ana');
    await register('Ana Silva', 'mariana');
    await register('Café Silva', 'cafe');
    const literal = await register('Literal Wildcard Name', 'literal');
    await prisma.user.update({ where: { id: literal.data.user.id }, data: { displayName: 'Literal 100%_\\ Name' } });
    const literalCharacters = await register('Literal Characters', 'literalchars');
    await prisma.user.update({ where: { id: literalCharacters.data.user.id }, data: { displayName: '% Percent _ Under \\ Backslash' } });
    const payload = await register('Payload User', 'payload');
    await prisma.user.update({ where: { id: payload.data.user.id }, data: { displayName: "x' OR 1=1 --" } });
    const validApostrophe = await register('Apostrophe Name', 'apostrophe');
    await prisma.user.update({ where: { id: validApostrophe.data.user.id }, data: { displayName: "O'Neil Person" } });
    const ranked = await Promise.all([
      register('Rankneedle Alpha', 'rankalpha'),
      register('Rankneedle Beta', 'rankbeta'),
      register('Rankneedle Gamma', 'rankgamma'),
      register('Rankneedle Delta', 'rankdelta'),
      register('Rankneedle Epsilon', 'rankepsilon'),
    ]);
    rankIds = ranked.map((user) => user.data.user.id);
    const exactUsername = await register('Rankneedle Exact', 'rankexact');
    const prefixUsername = await register('Rankneedle Prefix', 'rankprefix');
    exactUsernameId = exactUsername.data.user.id;
    prefixUsernameId = prefixUsername.data.user.id;
    await prisma.user.update({ where: { id: exactUsernameId }, data: { username: 'rankneedle' } });
    await prisma.user.update({ where: { id: prefixUsernameId }, data: { username: 'rankneedle_prefix' } });
    await prisma.follow.create({ data: { followerId: viewerId, followingId: ranked[2].data.user.id } });
    const extraFollowers = await Promise.all([
      register('Follower One', 'followerone'),
      register('Follower Two', 'followertwo'),
    ]);
    await prisma.follow.createMany({ data: extraFollowers.map((follower) => ({ followerId: follower.data.user.id, followingId: ranked[3].data.user.id })) });
    await prisma.block.createMany({ data: [
      { blockerId: viewerId, blockedId: ranked[3].data.user.id },
      { blockerId: ranked[4].data.user.id, blockedId: viewerId },
    ] });
  }, 120000);

  afterAll(async () => {
    try {
      try {
        await app?.close();
        expect(prismaInit).toHaveBeenCalledTimes(1);
        expect(prismaDestroy).toHaveBeenCalledTimes(1);
      } finally {
        try {
          await cleanDatabase(prisma);
        } finally {
          try {
            await prisma.$disconnect();
          } finally {
            await pool.end();
          }
        }
      }
    } finally {
      prismaInit?.mockRestore();
      prismaDestroy?.mockRestore();
    }
  });

  it('matches literal username/display-name word prefixes and returns truthful pages', async () => {
    const search = async (q: string, params = '') => {
      const result = await call(`/users/search?q=${encodeURIComponent(q)}${params}`);
      expect(result.status).toBe(200);
      return result.body.data;
    };
    expect((await search(' sil ')).users.map((user) => user.displayName)).toEqual(expect.arrayContaining(['Ana Silva', 'Café Silva']));
    expect((await search('ilv')).users).toEqual([]);
    expect((await search('ana')).users.map((user) => user.username)).toEqual(expect.arrayContaining([expect.stringMatching(/^ana_/)]));
    expect((await search('ana sil')).users.map((user) => user.displayName)).toContain('Ana Silva');
    expect((await search('café')).users.map((user) => user.displayName)).toContain('Café Silva');
    expect((await search('100%_\\')).users.map((user) => user.displayName)).toEqual(['Literal 100%_\\ Name']);
    for (const [term, expected] of [['%', '% Percent _ Under \\ Backslash'], ['_', '% Percent _ Under \\ Backslash'], ['\\', '% Percent _ Under \\ Backslash']] as const) {
      expect((await search(term)).users.map((user) => user.displayName)).toEqual([expected]);
      expect((await search(term)).users.map((user) => user.displayName)).not.toContain('Ana Silva');
    }
    const countBeforePayloadSearch = await prisma.user.count();
    expect((await search("x' OR 1=1 --")).users.map((user) => user.displayName)).toEqual(["x' OR 1=1 --"]);
    expect(await prisma.user.count()).toBe(countBeforePayloadSearch);
    expect((await search("o'neil")).users.map((user) => user.displayName)).toContain("O'Neil Person");
    expect((await search('o')).users.map((user) => user.displayName)).toContain("O'Neil Person");
    expect((await search('')).users.length).toBeGreaterThan(0);
    const page = await search(' sil ', '&limit=1&offset=0');
    expect(page.users).toHaveLength(1);
    expect(page.hasMore).toBe(true);
    expect(page.nextOffset).toBe(1);
    const middle = await search(' sil ', '&limit=1&offset=1');
    expect(middle.users).toHaveLength(1);
    expect(middle.hasMore).toBe(true);
    const last = await search(' sil ', '&limit=1&offset=3');
    expect(last.hasMore).toBe(false);
    expect(last.nextOffset).toBeNull();
  }, 120000);

  it('orders exact usernames before prefixes and names, with stable follower ranking', async () => {
    const response = await call('/users/search?q=rankneedle');
    expect(response.status).toBe(200);
    const users = response.body.data.users.filter((user) => user.displayName.startsWith('Rankneedle'));
    expect(users.slice(0, 2).map((user) => user.id)).toEqual([exactUsernameId, prefixUsernameId]);
    expect(users.findIndex((user) => user.id === rankIds[2])).toBeLessThan(users.findIndex((user) => user.id === rankIds[0]));
    const tied = users.filter((user) => [rankIds[0], rankIds[1]].includes(user.id)).map((user) => user.id);
    expect(tied).toEqual([rankIds[0], rankIds[1]].sort());
    const atSearch = await call('/users/search?q=%40rankneedle');
    expect(atSearch.body.data.users.map((user) => user.id)).toEqual([exactUsernameId, prefixUsernameId]);
    const emptyHandle = await call('/users/search?q=%40');
    expect(emptyHandle.body.data.users).toEqual([]);
  }, 120000);

  it('pages suggestions with stable non-overlapping results and preserves the users array', async () => {
    const followed = await register('Suggestion followed', 'suggestfollowed');
    const candidates = await Promise.all([
      register('Suggestion A', 'suggesta'),
      register('Suggestion B', 'suggestb'),
      register('Suggestion C', 'suggestc'),
    ]);
    await prisma.follow.create({ data: { followerId: viewerId, followingId: followed.data.user.id } });
    await prisma.follow.createMany({ data: candidates.map((candidate) => ({ followerId: followed.data.user.id, followingId: candidate.data.user.id })) });
    const firstResponse = await fetch(`${baseUrl}/users/suggestions?limit=2`, { headers: { Authorization: `Bearer ${token}`, 'X-Forwarded-For': `198.51.100.${++testCaseNumber}` } });
    const first: unknown = await firstResponse.json();
    expect(firstResponse.status).toBe(200);
    const firstData = suggestionsData(first);
    const firstUsers = firstData.users;
    expect(firstData).toMatchObject({ meta: { hasMore: true, nextOffset: 2 } });
    expect(firstUsers).toHaveLength(2);
    const secondResponse = await fetch(`${baseUrl}/users/suggestions?limit=2&offset=2`, { headers: { Authorization: `Bearer ${token}`, 'X-Forwarded-For': `198.51.100.${++testCaseNumber}` } });
    const second: unknown = await secondResponse.json();
    expect(secondResponse.status).toBe(200);
    const secondData = suggestionsData(second);
    expect(secondData.users).toHaveLength(1);
    expect(secondData.users.map((user) => user.id)).not.toEqual(expect.arrayContaining(firstUsers.map((user) => user.id)));
    expect(secondData.meta).toEqual({ hasMore: false, nextOffset: null });
  }, 120000);

  it('excludes blocks in either direction before pagination and keeps blank and one-character queries compatible', async () => {
    const response = await call('/users/search?q=rankneedle&limit=2&offset=0');
    expect(response.body.data.users.map((user) => user.id)).toEqual([exactUsernameId, prefixUsernameId]);
    expect(response.body.data.hasMore).toBe(true);
    const visible = await call('/users/search?q=rankneedle');
    expect(visible.body.data.users.map((user) => user.id)).not.toContain(rankIds[3]);
    expect(visible.body.data.users.map((user) => user.id)).not.toContain(rankIds[4]);
    const blank = await call('/users/search?q=%20%20');
    expect(blank.status).toBe(200);
    expect(blank.body.data.users.length).toBeGreaterThan(0);
    const oneCharacter = await call('/users/search?q=r');
    expect(oneCharacter.status).toBe(200);
    expect(oneCharacter.body.data.users.some((user) => user.username?.startsWith('rank'))).toBe(true);
  }, 120000);

  it('reports rows and continuation consistently for empty, partial, full, and overfull pages', async () => {
    const page = async (offset: number, limit: number) => {
      const result = await call(`/users/search?q=rankneedle&limit=${limit}&offset=${offset}`);
      expect(result.status).toBe(200);
      return result.body.data;
    };
    const empty = await page(0, 1);
    expect(empty.users).toHaveLength(1);
    expect(empty.hasMore).toBe(true);
    expect(empty.nextOffset).toBe(1);
    const underfilledLast = await page(4, 3);
    expect(underfilledLast.users).toHaveLength(1);
    expect(underfilledLast.hasMore).toBe(false);
    expect(underfilledLast.nextOffset).toBeNull();
    const oneShort = await page(3, 3);
    expect(oneShort.users).toHaveLength(2);
    expect(oneShort.hasMore).toBe(false);
    expect(oneShort.nextOffset).toBeNull();
    const exactLast = await page(2, 3);
    expect(exactLast.users).toHaveLength(3);
    expect(exactLast.hasMore).toBe(false);
    expect(exactLast.nextOffset).toBeNull();
    const noRows = await page(5, 3);
    expect(noRows.users).toHaveLength(0);
    expect(noRows.hasMore).toBe(false);
    expect(noRows.nextOffset).toBeNull();
  }, 120000);
});

function suggestionsData(value: unknown): { users: Array<{ id: string }>; meta: { hasMore: boolean; nextOffset: number | null } } {
  if (typeof value !== 'object' || value === null || !('data' in value) || typeof value.data !== 'object' || value.data === null || !('users' in value.data) || !Array.isArray(value.data.users) || !('meta' in value.data) || typeof value.data.meta !== 'object' || value.data.meta === null || !('hasMore' in value.data.meta) || typeof value.data.meta.hasMore !== 'boolean' || !('nextOffset' in value.data.meta) || (typeof value.data.meta.nextOffset !== 'number' && value.data.meta.nextOffset !== null)) throw new Error('Unexpected suggestions response');
  const users = value.data.users.filter((user): user is { id: string } => typeof user === 'object' && user !== null && 'id' in user && typeof user.id === 'string');
  if (users.length !== value.data.users.length) throw new Error('Unexpected suggestions response');
  return { users, meta: { hasMore: value.data.meta.hasMore, nextOffset: value.data.meta.nextOffset } };
}
