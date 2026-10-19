import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import type { Express } from 'express';
import * as fileUtils from '../../src/shared/utils/file.utils';
import { readdirSync } from 'node:fs';
import { join } from 'node:path';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { deleteUpload } from '../../src/shared/utils/file.utils';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });
type Actor = { id: string; token: string };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function dataOf(value: unknown): Record<string, unknown> {
  if (!isRecord(value) || !isRecord(value.data)) throw new Error('Expected API data envelope');
  return value.data;
}

function stringField(value: Record<string, unknown>, field: string): string {
  const result = value[field];
  if (typeof result !== 'string') throw new Error(`Expected ${field} string`);
  return result;
}

function arrayField(value: Record<string, unknown>, field: string): unknown[] {
  const result = value[field];
  if (!Array.isArray(result)) throw new Error(`Expected ${field} array`);
  return result;
}

describe('conversation API (HTTP + guarded PostgreSQL)', () => {
  let app: INestApplication | undefined;
  let baseUrl: string;
  let ipSequence = 0;
  let owner: Actor;
  let commenter: Actor;
  let mentioned: Actor;
  let postId: string;
  const uploadedFiles: string[] = [];
  const suffix = Date.now().toString(36);

  async function request(method: string, path: string, actor?: Actor, body?: object, idempotencyKey?: string) {
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}),
        'X-Forwarded-For': `198.51.100.${(++ipSequence % 240) + 1}`,
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(idempotencyKey ? { 'Idempotency-Key': idempotencyKey } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: response.status, body: await response.json() as unknown };
  }

  async function register(name: string): Promise<Actor> {
    const result = await request('POST', '/auth/register', undefined, {
      displayName: name, username: `${name}_${suffix}`.slice(0, 20),
      email: `${name}-${suffix}@example.com`, password: 'password123',
    });
    expect(result.status).toBe(201);
    const data = dataOf(result.body);
    const user = data.user;
    if (!isRecord(user)) throw new Error('Expected registered user');
    return { id: stringField(user, 'id'), token: stringField(data, 'token') };
  }

  async function comment(input: { content: string; parentId?: string; mentionIds?: string[]; clientRequestId?: string }, key?: string) {
    return request('POST', `/social/posts/${postId}/comments`, commenter, input, key);
  }

  async function commentWithMedia(input: { content: string; parentId?: string }, files: Array<{ name: string; mimeType: string; bytes: Buffer }>, actor: Actor, key?: string) {
    const form = new FormData();
    form.set('content', input.content);
    if (input.parentId) form.set('parentId', input.parentId);
    for (const file of files) form.append('media', new Blob([new Uint8Array(file.bytes)], { type: file.mimeType }), file.name);
    const response = await fetch(`${baseUrl}/social/posts/${postId}/comments`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${actor.token}`,
        'X-Forwarded-For': `198.51.100.${(++ipSequence % 240) + 1}`,
        ...(key ? { 'Idempotency-Key': key } : {}),
      },
      body: form,
    });
    const text = await response.text();
    let body: unknown = null;
    try { body = JSON.parse(text) as unknown; } catch { /* Some Multer errors are plain text. */ }
    return { status: response.status, body };
  }

  async function quoteWithImage(payload: { content: string; sourcePostId: string; mentionIds: string[]; clientRequestId: string }, bytes: Buffer) {
    const form = new FormData();
    form.set('content', payload.content);
    form.set('sourcePostId', payload.sourcePostId);
    form.set('clientRequestId', payload.clientRequestId);
    payload.mentionIds.forEach((id) => form.append('mentionIds[]', id));
    form.set('image', new Blob([new Uint8Array(bytes)], { type: 'image/png' }), 'quote.png');
    const response = await fetch(`${baseUrl}/social/quotes`, {
      method: 'POST', headers: { Authorization: `Bearer ${commenter.token}`, 'X-Forwarded-For': `198.51.100.${(++ipSequence % 240) + 1}`, 'Idempotency-Key': payload.clientRequestId }, body: form,
    });
    return { status: response.status, body: await response.json() as unknown };
  }

  async function uploadChatImage(actor: Actor): Promise<string> {
    const form = new FormData();
    form.set('file', new Blob([new Uint8Array(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]))], { type: 'image/png' }), 'chat.png');
    const response = await fetch(`${baseUrl}/uploads?context=chat`, {
      method: 'POST', headers: { Authorization: `Bearer ${actor.token}` }, body: form,
    });
    const body: unknown = await response.json();
    expect(response.status).toBe(201);
    const url = stringField(dataOf(body), 'url');
    uploadedFiles.push(url);
    return url;
  }

  beforeAll(async () => {
    assertSafeTestEnvironment();
    process.env.STRIPE_SECRET_KEY = 'sk_test_conversation_e2e_not_real';
    await prisma.$connect();
    await cleanDatabase(prisma);
    const { AppModule } = await import('../../src/app.module');
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
    owner = await register('owner');
    commenter = await register('commenter');
    mentioned = await register('mentioned');
    const createdPost = await request('POST', '/social/posts', owner, { type: 'REGULAR', content: 'Conversation fixture' });
    expect(createdPost.status).toBe(201);
    postId = stringField(dataOf(createdPost.body), 'id');
  }, 120000);

  afterAll(async () => {
    for (const url of uploadedFiles) deleteUpload(url);
    await app?.close();
    await prisma.$disconnect();
    await pool.end();
  });

  it('persists one canonical comment, mention, count and notification across replay; digest changes conflict', async () => {
    const key = 'conversation-idempotency-key-1';
    const payload = { content: 'hello @mentioned', mentionIds: [mentioned.id] };
    const first = await comment(payload, key);
    const retry = await comment(payload, key);
    expect(first.status).toBe(201);
    expect(retry.status).toBe(201);
    const canonicalId = stringField(dataOf(first.body), 'id');
    expect(stringField(dataOf(retry.body), 'id')).toBe(canonicalId);
    expect(await prisma.comment.count({ where: { postId } })).toBe(1);
    expect(await prisma.commentMention.count({ where: { commentId: canonicalId } })).toBe(1);
    expect((await prisma.post.findUniqueOrThrow({ where: { id: postId } })).commentsCount).toBe(1);
    expect(await prisma.notification.count({ where: { commentId: canonicalId } })).toBe(2);
    const conflict = await comment({ ...payload, content: 'changed payload' }, key);
    expect(conflict.status).toBe(409);
    expect(await prisma.comment.count({ where: { postId } })).toBe(1);
  });

  it('replays a live reply after its parent is deleted but rejects replay after the reply is deleted', async () => {
    const parent = await comment({ content: 'parent for replay' });
    const parentId = stringField(dataOf(parent.body), 'id');
    const key = 'conversation-parent-delete-replay';
    const payload = { content: 'reply for replay', parentId };
    const first = await comment(payload, key);
    const replyId = stringField(dataOf(first.body), 'id');

    expect((await request('PATCH', `/social/comments/${parentId}/delete`, commenter)).status).toBe(200);
    const retry = await comment(payload, key);
    expect(retry.status).toBe(201);
    expect(stringField(dataOf(retry.body), 'id')).toBe(replyId);

    expect((await request('PATCH', `/social/comments/${replyId}/delete`, commenter)).status).toBe(200);
    expect((await comment(payload, key)).status).toBe(400);
  });

  it('returns keyset conversation roots and continued root-to-parent context without changing legacy comments', async () => {
    const rootOne = await comment({ content: 'root one' });
    const rootOneId = stringField(dataOf(rootOne.body), 'id');
    let parentId = rootOneId;
    for (let index = 0; index < 34; index += 1) {
      const created = await comment({ content: `depth ${index}`, parentId });
      expect(created.status).toBe(201);
      parentId = stringField(dataOf(created.body), 'id');
    }
    await comment({ content: 'root two' });
    const firstPage = await request('GET', `/social/posts/${postId}/conversation?limit=1&sort=recent`, owner);
    expect(firstPage.status).toBe(200);
    const firstData = dataOf(firstPage.body);
    expect(Array.isArray(firstData.items)).toBe(true);
    expect(typeof firstData.nextCursor).toBe('string');
    const cursor = stringField(firstData, 'nextCursor');
    const secondPage = await request('GET', `/social/posts/${postId}/conversation?limit=1&sort=recent&cursor=${encodeURIComponent(cursor)}`, owner);
    expect(secondPage.status).toBe(200);
    const context = await request('GET', `/social/comments/${parentId}/context?replyLimit=1`, owner);
    expect(context.status).toBe(200);
    let contextData = dataOf(context.body);
    expect(Array.isArray(contextData.ancestors)).toBe(true);
    expect(arrayField(contextData, 'ancestors')).toHaveLength(32);
    expect(typeof contextData.nextAncestorCursor).toBe('string');
    const ancestorCursor = stringField(contextData, 'nextAncestorCursor');
    const continued = await request('GET', `/social/comments/${parentId}/context?replyLimit=1&ancestorCursor=${encodeURIComponent(ancestorCursor)}`, owner);
    contextData = dataOf(continued.body);
    expect(arrayField(contextData, 'ancestors')).toHaveLength(2);
    const legacy = await request('GET', `/social/posts/${postId}/comments?limit=2&offset=0`, owner);
    expect(legacy.status).toBe(200);
    if (!isRecord(legacy.body)) throw new Error('Expected response envelope');
    expect(Array.isArray(legacy.body.data)).toBe(true);
  });

  it('hides and restores public replies separately from pending moderation, with idempotent counts', async () => {
    const created = await comment({ content: 'hide me' });
    const commentId = stringField(dataOf(created.body), 'id');
    expect((await prisma.post.findUniqueOrThrow({ where: { id: postId } })).commentsCount).toBe(38);
    expect((await request('PATCH', `/social/comments/${commentId}/hide`, owner)).status).toBe(200);
    expect((await prisma.post.findUniqueOrThrow({ where: { id: postId } })).commentsCount).toBe(37);
    const hidden = await request('GET', `/social/posts/${postId}/hidden-replies`, owner);
    expect(hidden.status).toBe(200);
    expect(Array.isArray(dataOf(hidden.body).items)).toBe(true);
    await request('PATCH', `/social/comments/${commentId}/hide`, owner);
    expect((await prisma.post.findUniqueOrThrow({ where: { id: postId } })).commentsCount).toBe(37);
    expect((await request('PATCH', `/social/comments/${commentId}/unhide`, owner)).status).toBe(200);
    expect((await prisma.post.findUniqueOrThrow({ where: { id: postId } })).commentsCount).toBe(38);
  });

  it('reposts and bookmarks idempotently, filters inaccessible bookmarks before paging, and rejects duplicate reports', async () => {
    const first = await comment({ content: 'bookmark page one' });
    const firstId = stringField(dataOf(first.body), 'id');
    const second = await comment({ content: 'bookmark page two' });
    const secondId = stringField(dataOf(second.body), 'id');

    const repost = await request('POST', `/social/comments/${firstId}/repost`, commenter);
    const repostAgain = await request('POST', `/social/comments/${firstId}/repost`, commenter);
    expect(repost.status).toBe(201);
    expect(repostAgain.status).toBe(201);
    expect(stringField(dataOf(repost.body), 'id')).toBe(stringField(dataOf(repostAgain.body), 'id'));
    expect(await prisma.commentShare.count({ where: { userId: commenter.id, commentId: firstId } })).toBe(1);
    expect((await request('PATCH', `/social/comments/${firstId}/unrepost`, commenter)).status).toBe(200);
    expect((await request('PATCH', `/social/comments/${firstId}/unrepost`, commenter)).status).toBe(200);
    expect(await prisma.commentShare.count({ where: { userId: commenter.id, commentId: firstId } })).toBe(0);

    expect((await request('PUT', `/social/comments/${firstId}/bookmark`, commenter)).status).toBe(200);
    expect((await request('PUT', `/social/comments/${secondId}/bookmark`, commenter)).status).toBe(200);
    expect((await request('PUT', `/social/comments/${secondId}/bookmark`, commenter)).status).toBe(200);
    expect(await prisma.commentBookmark.count({ where: { userId: commenter.id, commentId: secondId } })).toBe(1);
    expect((await request('PATCH', `/social/comments/${secondId}/hide`, owner)).status).toBe(200);

    const bookmarkPage = await request('GET', '/social/comments/bookmarks?limit=1', commenter);
    expect(bookmarkPage.status).toBe(200);
    const page = dataOf(bookmarkPage.body);
    expect(arrayField(page, 'items')).toHaveLength(1);
    expect(page.nextCursor).toBeNull();
    const firstBookmark = arrayField(page, 'items')[0];
    if (!isRecord(firstBookmark)) throw new Error('Expected bookmarked comment');
    expect(stringField(firstBookmark, 'id')).toBe(firstId);

    const report = await request('POST', `/social/comments/${firstId}/report`, commenter, { reason: 'SPAM' });
    expect(report.status).toBe(201);
    expect(await prisma.report.count({ where: { reporterId: commenter.id, reportedCommentId: firstId } })).toBe(1);
    const duplicateReport = await request('POST', `/social/comments/${firstId}/report`, commenter, { reason: 'SPAM' });
    expect(duplicateReport.status).toBe(409);

    expect((await request('DELETE', `/social/comments/${secondId}/bookmark`, commenter)).status).toBe(200);
    expect((await request('DELETE', `/social/comments/${secondId}/bookmark`, commenter)).status).toBe(200);
    expect((await request('POST', `/social/comments/${secondId}/report`, commenter, { reason: 'SPAM' })).status).toBe(404);
  });

  it('rejects invalid comment media, more than four files, and payloads above 20 MiB before persistence', async () => {
    const invalidBytes = await commentWithMedia({ content: 'invalid media' }, [
      { name: 'not-image.png', mimeType: 'image/png', bytes: Buffer.from('not a PNG') },
    ], commenter);
    expect(invalidBytes.status).toBe(400);

    const files = Array.from({ length: 5 }, (_, index) => ({
      name: `image-${index}.png`, mimeType: 'image/png', bytes: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    }));
    expect((await commentWithMedia({ content: 'too many' }, files, commenter)).status).toBeGreaterThanOrEqual(400);

    const tooLarge = await commentWithMedia({ content: 'too large' }, [
      { name: 'large.png', mimeType: 'image/png', bytes: Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(20 * 1024 * 1024)]) },
    ], commenter);
    expect(tooLarge.status).toBeGreaterThanOrEqual(400);
    expect(await prisma.commentMedia.count()).toBe(0);
  }, 120000);

  it('replays concurrent identical media idempotently, conflicts on changed bytes, and authorizes private reads live', async () => {
    const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);
    const key = 'comment-media-concurrent-key';
    const [first, retry] = await Promise.all([
      commentWithMedia({ content: 'same media request' }, [{ name: 'same.png', mimeType: 'image/png', bytes: png }], commenter, key),
      commentWithMedia({ content: 'same media request' }, [{ name: 'same.png', mimeType: 'image/png', bytes: png }], commenter, key),
    ]);
    expect(first.status).toBe(201);
    expect(retry.status).toBe(201);
    const commentId = stringField(dataOf(first.body), 'id');
    expect(stringField(dataOf(retry.body), 'id')).toBe(commentId);
    expect(await prisma.commentMedia.count({ where: { commentId } })).toBe(1);
    const media = arrayField(dataOf(first.body), 'media');
    expect(media).toHaveLength(1);
    if (!isRecord(media[0])) throw new Error('Expected comment media projection');
    const mediaUrl = stringField(media[0], 'url');
    expect(stringField(media[0], 'mimeType')).toBe('image/png');
    expect((await fetch(`${baseUrl}${mediaUrl}`, { headers: { Authorization: `Bearer ${mentioned.token}` } })).status).toBe(200);
    const changed = await commentWithMedia({ content: 'same media request' }, [
      { name: 'changed.png', mimeType: 'image/png', bytes: Buffer.concat([png, Buffer.from([4])]) },
    ], commenter, key);
    expect(changed.status).toBe(409);
    expect(await prisma.commentMedia.count({ where: { commentId } })).toBe(1);

    await prisma.follow.create({ data: { followerId: owner.id, followingId: commenter.id } });
    await prisma.closeFriend.create({ data: { ownerId: owner.id, memberId: commenter.id } });
    await prisma.post.update({ where: { id: postId }, data: { audience: 'CLOSE_FRIENDS' } });
    expect((await fetch(`${baseUrl}${mediaUrl}`, { headers: { Authorization: `Bearer ${mentioned.token}` } })).status).toBe(404);
    const privateComment = await commentWithMedia({ content: 'private attachment' }, [
      { name: 'private.png', mimeType: 'image/png', bytes: png },
    ], commenter);
    expect(privateComment.status).toBe(201);
    const privateMedia = arrayField(dataOf(privateComment.body), 'media');
    if (!isRecord(privateMedia[0])) throw new Error('Expected private media projection');
    const privateUrl = stringField(privateMedia[0], 'url');
    expect((await fetch(`${baseUrl}${privateUrl}`)).status).toBe(401);
    expect((await fetch(`${baseUrl}${privateUrl}`, { headers: { Authorization: `Bearer ${mentioned.token}` } })).status).toBe(404);
    expect((await fetch(`${baseUrl}${privateUrl}`, { headers: { Authorization: `Bearer ${commenter.token}` } })).status).toBe(200);
    await prisma.closeFriend.delete({ where: { ownerId_memberId: { ownerId: owner.id, memberId: commenter.id } } });
    expect((await fetch(`${baseUrl}${privateUrl}`, { headers: { Authorization: `Bearer ${commenter.token}` } })).status).toBe(404);
  }, 120000);

  it('does not persist media when comment creation fails before the idempotency claim', async () => {
    const before = await prisma.commentMedia.count();
    const failed = await commentWithMedia({ content: 'invalid parent with media', parentId: '7f6d01ec-df1d-4d90-8e51-0f646b9771ef' }, [
      { name: 'valid.png', mimeType: 'image/png', bytes: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) },
    ], owner, 'comment-media-invalid-parent');
    expect(failed.status).toBe(400);
    expect(await prisma.commentMedia.count()).toBe(before);
  });

  it('creates idempotent public-post and comment quotes with canonical source projections', async () => {
    const source = await request('POST', '/social/posts', owner, { type: 'REGULAR', content: 'Quote source post' });
    expect(source.status).toBe(201);
    const sourcePostId = stringField(dataOf(source.body), 'id');
    await prisma.post.update({ where: { id: postId }, data: { audience: 'EVERYONE' } });
    const sourceComment = await comment({ content: 'Quote source comment' });
    const sourceCommentId = stringField(dataOf(sourceComment.body), 'id');
    const requestId = '80fdf92c-2e27-41f6-8e3e-bc7d93155343';
    const payload = { content: 'Quoting @mentioned', sourcePostId, mentionIds: [mentioned.id], clientRequestId: requestId };

    const [first, concurrent] = await Promise.all([
      request('POST', '/social/quotes', commenter, payload),
      request('POST', '/social/quotes', commenter, payload),
    ]);
    expect(first.status).toBe(201);
    expect(concurrent.status).toBe(201);
    const firstPost = dataOf(first.body);
    const quoteId = stringField(firstPost, 'id');
    expect(stringField(dataOf(concurrent.body), 'id')).toBe(quoteId);
    expect(firstPost.isQuote).toBe(true);
    expect(firstPost).not.toHaveProperty('quoteSourcePostId');
    expect(firstPost).not.toHaveProperty('quoteSourceCommentId');
    expect(firstPost.quoteSource).toEqual(expect.objectContaining({ kind: 'post', id: sourcePostId }));
    expect(await prisma.post.count({ where: { userId: commenter.id, clientRequestId: requestId } })).toBe(1);
    expect(await prisma.postMention.count({ where: { postId: quoteId, mentionedUserId: mentioned.id } })).toBe(1);
    expect(await prisma.notification.count({ where: { userId: mentioned.id, type: 'MENTION', data: { path: ['postId'], equals: quoteId } } })).toBe(1);

    const changed = await request('POST', '/social/quotes', commenter, { ...payload, content: 'Changed payload' });
    expect(changed.status).toBe(409);
    expect(await prisma.post.count({ where: { userId: commenter.id, clientRequestId: requestId } })).toBe(1);

    const commentRequestId = '2d171968-72b9-4365-b0a8-44ab467cd1d3';
    const quotedComment = await request('POST', '/social/quotes', commenter, {
      content: 'Quoting a comment', sourceCommentId: sourceCommentId, clientRequestId: commentRequestId,
    });
    expect(quotedComment.status).toBe(201);
    expect(dataOf(quotedComment.body).quoteSource).toEqual(expect.objectContaining({ kind: 'comment', id: sourceCommentId }));
    expect(await prisma.post.findUniqueOrThrow({ where: { id: stringField(dataOf(quotedComment.body), 'id') } }))
      .toMatchObject({ isQuote: true, quoteSourceCommentId: sourceCommentId, quoteSourcePostId: null });
  });

  it('claims an image quote before one canonical upload on concurrent replay and preserves it on payload conflict', async () => {
    const source = await request('POST', '/social/posts', owner, { type: 'REGULAR', content: 'Image quote source' });
    const sourcePostId = stringField(dataOf(source.body), 'id');
    const requestId = 'c43464a8-2448-40df-89b5-56f22a7bba53';
    const payload = { content: 'Image quote @mentioned', sourcePostId, mentionIds: [mentioned.id], clientRequestId: requestId };
    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC', 'base64');
    const directory = join(process.cwd(), 'uploads', 'post');
    const beforeFiles = new Set(readdirSync(directory));
    const saveSpy = jest.spyOn(fileUtils, 'saveUpload');
    try {
      const [first, retry] = await Promise.all([quoteWithImage(payload, png), quoteWithImage(payload, png)]);
      if (first.status !== 201) throw new Error(JSON.stringify(first.body));
      expect(retry.status).toBe(201);
      const canonical = stringField(dataOf(first.body), 'id');
      expect(stringField(dataOf(retry.body), 'id')).toBe(canonical);
      const imageUrl = stringField(dataOf(first.body), 'imageUrl');
      expect(stringField(dataOf(retry.body), 'imageUrl')).toBe(imageUrl);
      expect(saveSpy).toHaveBeenCalledTimes(1);
      expect(await prisma.post.count({ where: { userId: commenter.id, clientRequestId: requestId } })).toBe(1);
      expect(await prisma.postMention.count({ where: { postId: canonical, mentionedUserId: mentioned.id } })).toBe(1);
      expect(await prisma.postMention.count({ where: { postId: canonical } })).toBe(1);
      expect(await prisma.notification.count({ where: { userId: mentioned.id, type: 'MENTION', data: { path: ['postId'], equals: canonical } } })).toBe(1);
      const afterFiles = readdirSync(directory).filter((name) => !beforeFiles.has(name));
      expect(afterFiles).toEqual([imageUrl.slice('/uploads/post/'.length)]);
      const changed = await quoteWithImage({ ...payload, content: 'Different image quote' }, Buffer.concat([png, Buffer.from([4])]));
      expect(changed.status).toBe(409);
      expect(saveSpy).toHaveBeenCalledTimes(1);
      expect((await prisma.post.findUniqueOrThrow({ where: { id: canonical } })).imageUrl).toBe(imageUrl);
    } finally {
      saveSpy.mockRestore();
      for (const name of readdirSync(directory).filter((entry) => !beforeFiles.has(entry))) deleteUpload(`/uploads/post/${name}`);
    }
  }, 120000);

  it('rejects absent, ambiguous, and unavailable quote sources without creating posts', async () => {
    const before = await prisma.post.count({ where: { userId: commenter.id } });
    const requestId = 'bc11a475-cf0d-4858-9bc3-0de110bc1376';
    for (const payload of [
      { content: 'no source', clientRequestId: requestId },
      { content: 'two sources', sourcePostId: postId, sourceCommentId: '7f6d01ec-df1d-4d90-8e51-0f646b9771ef', clientRequestId: requestId },
      { content: 'missing source', sourcePostId: '7f6d01ec-df1d-4d90-8e51-0f646b9771ef', clientRequestId: requestId },
    ]) {
      expect((await request('POST', '/social/quotes', commenter, payload)).status).toBeGreaterThanOrEqual(400);
    }
    expect(await prisma.post.count({ where: { userId: commenter.id } })).toBe(before);
  });

  it('binds uploaded chat media to its uploader while allowing the conversation recipient to fetch it', async () => {
    const recipient = await register('mediarecipient');
    const uploader = await register('mediaowner');
    const attacker = await register('mediaattacker');
    const uploaderFile = await uploadChatImage(uploader);
    const [attackerConversation, ownerConversation] = await Promise.all([
      request('POST', '/chat/conversations', attacker, { targetUserId: recipient.id }),
      request('POST', '/chat/conversations', uploader, { targetUserId: recipient.id }),
    ]);
    expect(attackerConversation.status).toBe(201);
    expect(ownerConversation.status).toBe(201);
    const attackerConversationId = stringField(dataOf(attackerConversation.body), 'conversationId');
    const ownerConversationId = stringField(dataOf(ownerConversation.body), 'conversationId');

    const theftAttempt = await request('POST', `/chat/conversations/${attackerConversationId}/messages`, attacker, {
      type: 'IMAGE', content: '', attachmentUrl: uploaderFile,
    });
    expect(theftAttempt.status).toBe(400);
    expect(await prisma.directMessage.count({ where: { conversationId: attackerConversationId } })).toBe(0);

    const attackerFile = await uploadChatImage(attacker);
    const sent = await request('POST', `/chat/conversations/${attackerConversationId}/messages`, attacker, {
      type: 'IMAGE', content: '', attachmentUrl: attackerFile,
    });
    expect(sent.status).toBe(201);
    expect((await fetch(`${baseUrl}${attackerFile}`, { headers: { Authorization: `Bearer ${recipient.token}` } })).status).toBe(200);
    expect((await fetch(`${baseUrl}${attackerFile}`, { headers: { Authorization: `Bearer ${uploader.token}` } })).status).toBe(404);
    expect(await prisma.directMessage.count({ where: { conversationId: ownerConversationId } })).toBe(0);
  });
});
