import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import type { Express } from 'express';
import { AppModule } from '../../src/app.module';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

type Body = { data: Record<string, unknown>; error?: { code: string } };

describe('Story audiences and safety (HTTP + real database)', () => {
  let app: INestApplication | undefined;
  let baseUrl: string;
  let testClientIp: string | undefined;
  let testCaseNumber = 0;
  let actors: { owner: { id: string; token: string }; friend: { id: string; token: string }; follower: { id: string; token: string }; stranger: { id: string; token: string } };
  const suffix = Date.now().toString(36);

  async function call(method: string, path: string, token?: string, body?: object) {
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(testClientIp ? { 'X-Forwarded-For': testClientIp } : {}),
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await response.json() as Body;
    if (response.status === 429) throw new Error(`${method} ${path} returned 429: ${JSON.stringify(json)}`);
    return { status: response.status, json };
  }

  async function register(name: string) {
    const response = await call('POST', '/auth/register', undefined, {
      displayName: name, username: `${name}_${suffix}`.slice(0, 20),
      email: `${name}-${suffix}@example.com`, password: 'password123',
    });
    expect(response.status).toBe(201);
    return { id: (response.json.data.user as { id: string }).id, token: response.json.data.token as string };
  }

  async function publish(token: string, audience: string) {
    const form = new FormData();
    form.append('image', new Blob([Buffer.from('89504e470d0a1a0a00000000', 'hex')], { type: 'image/png' }), 'story.png');
    form.append('audience', audience);
    const response = await fetch(`${baseUrl}/stories`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, ...(testClientIp ? { 'X-Forwarded-For': testClientIp } : {}) }, body: form,
    });
    return { status: response.status, json: await response.json() as Body };
  }

  async function startApplication() {
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const application = module.createNestApplication();
    app = application;
    const expressApp: Express = application.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', 'loopback');
    application.useGlobalPipes(createValidationPipe());
    application.useGlobalFilters(new AllExceptionsFilter());
    application.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await application.init();
    await application.listen(0);
    const address = application.getHttpServer().address();
    if (!address || typeof address === 'string') throw new Error('No HTTP port');
    baseUrl = `http://127.0.0.1:${address.port}`;
  }

  beforeAll(async () => {
    assertSafeTestEnvironment();
    if (process.env.STRIPE_SECRET_KEY === 'e2e_fake_stripe_key_not_real') {
      process.env.STRIPE_SECRET_KEY = 'sk_test_story_audience_e2e_not_real';
    }
    await prisma.$connect();
    await cleanDatabase(prisma);
    await startApplication();
    actors = {
      owner: await register('owner'),
      friend: await register('friend'),
      follower: await register('follower'),
      stranger: await register('stranger'),
    };
  }, 120000);

  beforeEach(async () => {
    testClientIp = `198.51.100.${++testCaseNumber}`;
  });

  afterAll(async () => {
    await app?.close();
    await cleanDatabase(prisma);
    await prisma.$disconnect();
    await pool.end();
  });

  it('limits close-friends stories, highlights, views and bytes to current listed followers', async () => {
    const { owner, friend, follower, stranger } = actors;
    for (const user of [friend, follower]) {
      expect((await call('POST', `/users/${owner.id}/follow`, user.token)).status).toBe(200);
    }
    expect((await call('POST', `/users/me/close-friends/${friend.id}`, owner.token)).status).toBe(201);
    const candidates = await call('GET', '/users/me/close-friends/candidates?q=fri', owner.token);
    expect(candidates.status).toBe(200);
    expect(candidates.json.data.users).toEqual([expect.objectContaining({ id: friend.id, isCloseFriend: true })]);
    expect((await call('GET', '/users/me/close-friends/candidates?selected=true', owner.token)).json.data.users)
      .toEqual([expect.objectContaining({ id: friend.id })]);
    const created = await publish(owner.token, 'CLOSE_FRIENDS');
    expect(created.status).toBe(201);
    const story = created.json.data as { id: string; imageUrl: string; audience: string };
    expect(story.audience).toBe('CLOSE_FRIENDS');
    expect(story.imageUrl).toMatch(/\/media\/story\//);
    expect((await call('GET', `/users/${owner.id}`, follower.token)).json.data.hasActiveStory).toBe(false);
    expect((await call('GET', `/users/${owner.id}`, friend.token)).json.data.hasActiveStory).toBe(true);

    const feed = async (token: string) => (await call('GET', '/stories', token)).json.data.stories as { stories: { id: string }[] }[];
    const hasStory = async (token: string) => (await feed(token)).some((group) => group.stories.some((item) => item.id === story.id));
    expect(await hasStory(owner.token)).toBe(true);
    expect(await hasStory(friend.token)).toBe(true);
    expect(await hasStory(follower.token)).toBe(false);
    expect(await hasStory(stranger.token)).toBe(false);
    expect((await call('GET', `/stories/user/${owner.id}`, follower.token)).json.data).toEqual([]);
    expect((await call('POST', `/stories/${story.id}/view`, follower.token)).status).toBe(404);
    expect(await prisma.storyView.count({ where: { storyId: story.id } })).toBe(0);
    const mediaPath = new URL(story.imageUrl, baseUrl).pathname;
    expect((await fetch(`${baseUrl}${mediaPath}`)).status).toBe(401);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${follower.token}` } })).status).toBe(404);
    const privateMedia = await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } });
    expect(privateMedia.status).toBe(200);
    expect(privateMedia.headers.get('cache-control')).toContain('no-store');
    expect((await call('POST', `/stories/${story.id}/view`, friend.token)).status).toBe(201);

    const highlight = await call('POST', '/stories/highlights', owner.token, { title: 'Private', storyIds: [story.id], coverStoryId: story.id });
    expect(highlight.status).toBe(201);
    const highlightId = highlight.json.data.id as string;
    expect((await call('GET', `/stories/highlights/user/${owner.id}`, follower.token)).json.data.highlights).toEqual([]);
    expect((await call('GET', `/stories/highlights/${highlightId}`, follower.token)).status).toBe(404);
    expect((await call('GET', `/stories/highlights/${highlightId}`, friend.token)).status).toBe(200);

    expect((await call('PATCH', `/users/me/close-friends/${friend.id}/remove`, owner.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await call('GET', `/stories/highlights/${highlightId}`, friend.token)).status).toBe(404);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } })).status).toBe(404);
    expect((await call('GET', '/users/me/close-friends', friend.token)).json.data.users).toEqual([]);
    expect((await call('POST', `/users/me/close-friends/${stranger.id}`, owner.token)).status).toBe(400);
    expect((await call('POST', `/users/me/close-friends/${friend.id}`, owner.token)).status).toBe(201);
    expect(await hasStory(friend.token)).toBe(true);

    expect((await call('PATCH', `/users/${owner.id}/unfollow`, friend.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } })).status).toBe(404);
    expect((await call('POST', `/users/${owner.id}/follow`, friend.token)).status).toBe(200);
    expect((await call('POST', `/users/${friend.id}/block`, owner.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await call('GET', '/users/blocked', owner.token)).json.data.users).toEqual(expect.arrayContaining([expect.objectContaining({ id: friend.id })]));
    expect((await call('GET', '/users/me/close-friends', owner.token)).json.data.users).toEqual([]);
    expect((await call('PATCH', `/users/${friend.id}/unblock`, owner.token)).status).toBe(200);
  }, 120000);

  it('keeps restricted comments private until approved and exposes a reversible safety list', async () => {
    const { owner, stranger: restricted, follower: outsider } = actors;
    expect((await call('POST', `/users/me/restricted/${restricted.id}`, owner.token)).status).toBe(201);
    expect((await call('GET', '/users/me/restricted', owner.token)).json.data.users).toEqual(expect.arrayContaining([expect.objectContaining({ id: restricted.id })]));
    const post = await prisma.post.create({ data: { userId: owner.id, type: 'REGULAR', content: 'hello' } });
    const comment = await call('POST', `/social/posts/${post.id}/comments`, restricted.token, { content: 'hidden' });
    expect(comment.status).toBe(201);
    const commentId = comment.json.data.id as string;
    expect(await prisma.comment.findUnique({ where: { id: commentId }, select: { isHidden: true } }))
      .toEqual({ isHidden: true });
    expect((await call('POST', `/social/comments/${commentId}/like`, outsider.token)).status).toBe(404);
    expect((await call('POST', `/social/posts/${post.id}/comments`, outsider.token, { content: 'reply', parentId: commentId })).status).toBe(400);
    expect((await call('GET', `/social/posts/${post.id}`, outsider.token)).json.data.commentsCount).toBe(0);
    const comments = async (token: string): Promise<{ id: string }[]> => {
      const data = (await call('GET', `/social/posts/${post.id}/comments`, token)).json.data;
      return Array.isArray(data) ? data : [];
    };
    expect((await comments(restricted.token)).map((item) => item.id)).toContain(commentId);
    expect((await comments(owner.token)).map((item) => item.id)).toContain(commentId);
    expect((await comments(outsider.token)).map((item) => item.id)).not.toContain(commentId);
    expect((await call('PATCH', `/social/comments/${commentId}/approve`, outsider.token)).status).toBe(404);
    expect((await call('PATCH', `/users/me/restricted/${restricted.id}/remove`, owner.token)).status).toBe(200);
    expect((await comments(outsider.token)).map((item) => item.id)).not.toContain(commentId);
    expect((await call('PATCH', `/social/comments/${commentId}/approve`, owner.token)).status).toBe(200);
    expect((await comments(outsider.token)).map((item) => item.id)).toContain(commentId);
    expect((await call('GET', `/social/posts/${post.id}`, outsider.token)).json.data.commentsCount).toBe(1);
    expect((await call('GET', '/users/me/restricted', owner.token)).json.data.users).toEqual([]);
  }, 120000);

  it('keeps close-friends posts and their media out of public discovery and revokes access', async () => {
    const { owner: author, friend, follower, stranger: outsider } = actors;
    await prisma.block.deleteMany({ where: { blockerId: author.id, blockedId: friend.id } });
    await prisma.follow.createMany({ data: [
      { followerId: friend.id, followingId: author.id },
      { followerId: follower.id, followingId: author.id },
    ], skipDuplicates: true });
    expect((await call('POST', `/users/me/close-friends/${friend.id}`, author.token)).status).toBe(201);
    const form = new FormData();
    form.append('type', 'REGULAR');
    form.append('audience', 'CLOSE_FRIENDS');
    form.append('content', 'a private memory');
    form.append('image', new Blob([Buffer.from('89504e470d0a1a0a00000000', 'hex')], { type: 'image/png' }), 'post.png');
    const createdResponse = await fetch(`${baseUrl}/social/posts`, {
      method: 'POST', headers: { Authorization: `Bearer ${author.token}`, ...(testClientIp ? { 'X-Forwarded-For': testClientIp } : {}) }, body: form,
    });
    expect(createdResponse.status).toBe(201);
    const created = await createdResponse.json() as Body;
    const post = created.data as { id: string; imageUrl: string; audience: string };
    expect(post.audience).toBe('CLOSE_FRIENDS');
    expect(post.imageUrl).toMatch(/\/media\/privatepost\//);
    const publicCount = await prisma.post.count({ where: { userId: author.id, audience: 'EVERYONE', deletedAt: null } });
    expect((await call('GET', `/users/${author.id}`, outsider.token)).json.data.postsCount).toBe(publicCount);
    expect((await call('GET', `/users/${author.id}`, friend.token)).json.data.postsCount).toBe(publicCount + 1);
    const postPath = `/social/posts/${post.id}`;
    const readList = async (path: string, token: string) => (await call('GET', path, token)).json.data;
    expect((await call('GET', postPath, friend.token)).status).toBe(200);
    expect((await call('GET', postPath, follower.token)).status).toBe(404);
    expect((await call('GET', postPath, outsider.token)).status).toBe(404);
    expect((await call('GET', postPath)).status).toBe(404);
    for (const path of [
      '/social/feed', '/social/feed?type=following', '/social/posts/search?q=memory',
      `/social/posts/user/${author.id}`, `/social/posts/user/${author.id}/timeline`,
    ]) {
      expect(JSON.stringify(await readList(path, follower.token))).not.toContain(post.id);
      expect(JSON.stringify(await readList(path, friend.token))).toContain(post.id);
    }
    expect((await call('POST', `${postPath}/like`, outsider.token)).status).toBe(404);
    expect((await call('POST', `${postPath}/comments`, outsider.token, { content: 'nope' })).status).toBe(404);
    expect((await call('POST', `${postPath}/save`, outsider.token)).status).toBe(404);
    expect((await call('POST', `${postPath}/share`, friend.token)).status).toBe(400);
    expect((await call('POST', `${postPath}/like`, friend.token)).status).toBe(201);
    expect((await call('POST', `${postPath}/save`, friend.token)).status).toBe(201);
    expect((await call('POST', `${postPath}/comments`, friend.token, { content: 'nice' })).status).toBe(201);
    expect(JSON.stringify(await readList(`${postPath}/comments`, outsider.token))).not.toContain('nice');
    const mediaPath = new URL(post.imageUrl, baseUrl).pathname;
    expect((await fetch(`${baseUrl}${mediaPath}`)).status).toBe(401);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${follower.token}` } })).status).toBe(404);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } })).status).toBe(200);
    expect((await call('PATCH', `/users/me/close-friends/${friend.id}/remove`, author.token)).status).toBe(200);
    expect((await call('GET', postPath, friend.token)).status).toBe(404);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } })).status).toBe(404);
    expect(JSON.stringify(await readList('/social/posts/liked', friend.token))).not.toContain(post.id);
    expect(JSON.stringify(await readList('/social/posts/saved', friend.token))).not.toContain(post.id);
  }, 120000);

  it('allows either connection direction and revokes only after the final edge is lost', async () => {
    const { owner, friend, follower, stranger } = actors;
    await prisma.follow.deleteMany({ where: { OR: [
      { followerId: owner.id, followingId: { in: [friend.id, follower.id] } },
      { followingId: owner.id, followerId: { in: [friend.id, follower.id] } },
    ] } });
    await prisma.closeFriend.deleteMany({ where: { ownerId: owner.id, memberId: { in: [friend.id, follower.id] } } });
    await prisma.block.deleteMany({ where: { OR: [
      { blockerId: owner.id, blockedId: { in: [friend.id, follower.id] } },
      { blockedId: owner.id, blockerId: { in: [friend.id, follower.id] } },
    ] } });
    await prisma.follow.createMany({ data: [
      { followerId: friend.id, followingId: owner.id },
      { followerId: owner.id, followingId: friend.id },
      { followerId: owner.id, followingId: follower.id },
    ], skipDuplicates: true });
    const candidates = await call('GET', '/users/me/close-friends/candidates', owner.token);
    expect((candidates.json.data.users as { id: string }[]).map(({ id }) => id)).toEqual(expect.arrayContaining([friend.id, follower.id]));
    for (const member of [friend, follower]) {
      expect((await call('POST', `/users/me/close-friends/${member.id}`, owner.token)).status).toBe(201);
    }
    expect((await call('POST', `/users/me/close-friends/${owner.id}`, owner.token)).status).toBe(400);
    const created = await publish(owner.token, 'CLOSE_FRIENDS');
    const story = created.json.data as { id: string };
    const postForm = new FormData();
    postForm.append('type', 'REGULAR');
    postForm.append('audience', 'CLOSE_FRIENDS');
    postForm.append('content', 'private connection post');
    postForm.append('image', new Blob([Buffer.from('89504e470d0a1a0a00000000', 'hex')], { type: 'image/png' }), 'post.png');
    const postResponse = await fetch(`${baseUrl}/social/posts`, {
      method: 'POST', headers: { Authorization: `Bearer ${owner.token}`, ...(testClientIp ? { 'X-Forwarded-For': testClientIp } : {}) }, body: postForm,
    });
    expect(postResponse.status).toBe(201);
    const postData = await postResponse.json() as Body;
    const privatePost = postData.data as { id: string; imageUrl: string };
    const hasStory = async (token: string) => {
      const response = await call('GET', '/stories', token);
      if (response.status !== 200) throw new Error(`GET /stories returned ${response.status}: ${JSON.stringify(response.json)}`);
      const groups = response.json.data.stories as { stories: { id: string }[] }[];
      return groups.some((group) => group.stories.some((item) => item.id === story.id));
    };
    expect(await hasStory(friend.token)).toBe(true);
    expect(await hasStory(follower.token)).toBe(true);
    expect(await hasStory(stranger.token)).toBe(false);
    expect((await call('GET', `/social/posts/${privatePost.id}`, friend.token)).status).toBe(200);
    expect((await call('GET', `/social/posts/${privatePost.id}`, follower.token)).status).toBe(200);
    expect((await call('GET', `/social/posts/${privatePost.id}`, stranger.token)).status).toBe(404);
    const mediaPath = new URL(privatePost.imageUrl, baseUrl).pathname;
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${follower.token}` } })).status).toBe(200);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${stranger.token}` } })).status).toBe(404);

    expect((await call('PATCH', `/users/${owner.id}/unfollow`, friend.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(true);
    expect((await call('GET', `/social/posts/${privatePost.id}`, friend.token)).status).toBe(200);
    expect((await call('PATCH', `/users/${friend.id}/unfollow`, owner.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await call('GET', `/social/posts/${privatePost.id}`, friend.token)).status).toBe(404);
    expect((await fetch(`${baseUrl}${mediaPath}`, { headers: { Authorization: `Bearer ${friend.token}` } })).status).toBe(404);
    expect((await call('POST', `/users/${owner.id}/follow`, friend.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await call('POST', `/users/${friend.id}/block`, owner.token)).status).toBe(200);
    expect((await call('PATCH', `/users/${friend.id}/unblock`, owner.token)).status).toBe(200);
    expect((await call('POST', `/users/me/close-friends/${friend.id}`, owner.token)).status).toBe(400);
    expect((await call('POST', `/users/${owner.id}/follow`, friend.token)).status).toBe(200);
    expect(await hasStory(friend.token)).toBe(false);
    expect((await call('POST', `/users/me/close-friends/${friend.id}`, owner.token)).status).toBe(201);
    expect(await hasStory(friend.token)).toBe(true);

    expect((await call('PATCH', `/users/${follower.id}/unfollow`, owner.token)).status).toBe(200);
    expect(await hasStory(follower.token)).toBe(false);
    expect((await call('POST', `/users/me/close-friends/${follower.id}`, owner.token)).status).toBe(400);
  }, 120000);
});
