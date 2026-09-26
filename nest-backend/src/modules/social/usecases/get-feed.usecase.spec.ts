import { Test } from '@nestjs/testing';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { GetFeedUseCase } from './get-feed.usecase';
import { FeedType } from '../types/social.types';

describe('GetFeedUseCase cursor validation', () => {
  it.each([
    [
      'wrong scope',
      Buffer.from(
        JSON.stringify({
          scope: 'other-feed',
          userId: 'viewer-1',
          type: 'following',
          contentFilter: 'all',
          createdAt: '2026-09-12T00:00:00.000Z',
          postId: 'post-1',
        }),
      ).toString('base64url'),
    ],
    [
      'wrong feed type',
      Buffer.from(
        JSON.stringify({
          scope: 'following-feed',
          userId: 'viewer-1',
          type: 'following',
          contentFilter: 'all',
          createdAt: '2026-09-12T00:00:00.000Z',
          postId: 'post-1',
        }),
      ).toString('base64url'),
    ],
  ])('returns a typed 4xx and does not call the repository for %s', async (name, cursor) => {
    const findFeed = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        GetFeedUseCase,
        { provide: PrismaPostRepository, useValue: { findFeed } },
      ],
    }).compile();

    const result = await module.get(GetFeedUseCase).execute({
      userId: 'viewer-1',
      type: name === 'wrong feed type' ? FeedType.EXPLORE : FeedType.FOLLOWING,
      cursor,
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(400);
    expect(findFeed).not.toHaveBeenCalled();
  });
});
