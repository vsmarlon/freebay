import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PostPayload } from '../../types/social.types';
import { normalizePostsForViewer } from './post-query-helpers';

function post(overrides: Partial<PostPayload> = {}): PostPayload {
  return {
    id: 'post-id', content: 'commentary', imageUrl: null, imageBlurHash: null,
    type: 'REGULAR', audience: 'EVERYONE', userId: 'author-id', likesCount: 0,
    commentsCount: 0, sharesCount: 0, createdAt: new Date('2026-10-15T00:00:00Z'),
    updatedAt: new Date('2026-10-15T00:00:00Z'), deletedAt: null,
    clientRequestId: 'private-request-id', clientRequestHash: 'private-hash',
    quoteSourcePostId: null, quoteSourceCommentId: null, isQuote: false,
    replyPermission: 'EVERYONE',
    user: { id: 'author-id', displayName: 'Author', username: 'author', avatarUrl: null, avatarBlurHash: null, isVerified: false },
    product: null, likes: [], shares: [], savedBy: [],
    _count: { likes: 0, comments: 0, shares: 0 },
    ...overrides,
  };
}

describe('quote response projection', () => {
  it('returns only a currently eligible source and never exposes idempotency internals', async () => {
    const sourcePost = post({ id: 'source-id', content: 'original', userId: 'source-author' });
    const findMany = jest.fn().mockResolvedValue([sourcePost]);
    const module = await Test.createTestingModule({ providers: [
      { provide: PrismaService, useValue: { post: { findMany }, comment: { findMany: jest.fn() } } },
    ] }).compile();
    const quote = post({ isQuote: true, quoteSourcePostId: 'source-id' });

    const [response] = await normalizePostsForViewer([quote], 'viewer-id', module.get(PrismaService));

    expect(response.isQuote).toBe(true);
    expect(response.quoteSource).toEqual(expect.objectContaining({ kind: 'post', id: 'source-id', post: expect.objectContaining({ content: 'original' }) }));
    expect(response).not.toHaveProperty('clientRequestId');
    expect(response).not.toHaveProperty('clientRequestHash');
    expect(response).not.toHaveProperty('quoteSourcePostId');
    expect(response).not.toHaveProperty('quoteSourceCommentId');

    findMany.mockResolvedValueOnce([]);
    const [unavailable] = await normalizePostsForViewer([quote], 'viewer-id', module.get(PrismaService));
    expect(unavailable.quoteSource).toBeNull();
  });
});
