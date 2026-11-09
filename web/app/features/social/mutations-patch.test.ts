import { describe, expect, it } from 'vitest';
import { QueryClient } from '@tanstack/react-query';
import { patchCommentInPages, patchPostInRecord, socialKeys } from './queries';
import type { Comment, CursorPage, FeedPage, Post, TimelineEntry } from './types';

const post = (id: string, overrides: Partial<Post> = {}): Post => ({
  id,
  userId: 'owner',
  content: null,
  media: [],
  type: 'REGULAR',
  audience: 'EVERYONE',
  likesCount: 0,
  commentsCount: 0,
  sharesCount: 0,
  isLiked: false,
  isSaved: false,
  hasReposted: false,
  createdAt: '2026-01-01T00:00:00.000Z',
  user: { id: 'owner', displayName: 'Member' },
  ...overrides,
});

const entry = (postId: string, overrides: Partial<TimelineEntry> = {}): TimelineEntry => ({
  post: post(postId),
  repostId: `${postId}-share`,
  repostedAt: '2026-01-02T00:00:00.000Z',
  repostedBy: { id: 'owner', displayName: 'Member' },
  isReposted: true,
  sharesCount: 0,
  ...overrides,
});

const comment = (id: string, replies: Comment[] = []): Comment => ({
  id,
  postId: 'p1',
  userId: 'u',
  content: `${id}-body`,
  parentId: null,
  createdAt: '2026-01-01T00:00:00.000Z',
  likesCount: 0,
  isLiked: false,
  isHidden: false,
  replies,
});

const likeState = { isLiked: true, likesCount: 4 };

describe('patchPostInRecord (authoritative mutation merge)', () => {
  it('patches the post inside FeedPage.posts', () => {
    const page: FeedPage = { posts: [post('p1'), post('p2')], hasMore: false, nextCursor: null };
    expect(patchPostInRecord(page, 'p2', likeState)).toMatchObject({
      posts: [
        { id: 'p1', isLiked: false },
        { id: 'p2', isLiked: true, likesCount: 4 },
      ],
    });
  });

  it('patches the post inside CursorPage items', () => {
    const page: CursorPage<Post> = { items: [post('p1')], hasMore: false, nextCursor: null };
    expect(patchPostInRecord(page, 'p1', likeState)).toMatchObject({
      items: [{ isLiked: true, likesCount: 4 }],
    });
  });

  it('patches the post inside timeline entries and leaves the owner flag alone', () => {
    const page: CursorPage<TimelineEntry> = {
      items: [entry('p1')],
      hasMore: false,
      nextCursor: null,
    };
    expect(patchPostInRecord(page, 'p1', likeState)).toMatchObject({
      items: [{ post: { isLiked: true, likesCount: 4 }, isReposted: true }],
    });
  });

  it('patches a bare post-detail object and skips unrelated shapes', () => {
    expect(patchPostInRecord(post('p1'), 'p1', likeState)).toMatchObject({
      id: 'p1',
      likesCount: 4,
    });
    expect(patchPostInRecord({ unrelated: true }, 'p1', likeState)).toEqual({ unrelated: true });
    expect(patchPostInRecord([post('p1')], 'p1', likeState)).toEqual([post('p1', likeState)]);
  });

  it('writes through infinite pages and liked lists without changing pagination or unrelated cache data', () => {
    const client = new QueryClient();
    const keys = socialKeys('viewer');
    const other = post('other');
    const pageParams = [undefined, 'cursor'];
    const feed = {
      pages: [
        { posts: [other], hasMore: true, nextCursor: 'cursor' },
        { posts: [post('p1')], hasMore: false, nextCursor: null },
      ],
      pageParams,
    };
    const saved = {
      pages: [{ items: [post('p1'), other], hasMore: true, nextCursor: 'saved-cursor' }],
      pageParams: [undefined],
    };
    const timeline = {
      pages: [{ items: [entry('p1')], hasMore: false, nextCursor: null }],
      pageParams: [undefined],
    };
    const outside = socialKeys('other-viewer').feed;
    client.setQueryData(keys.feed, feed);
    client.setQueryData(keys.saved, saved);
    client.setQueryData(keys.timeline('owner:all'), timeline);
    client.setQueryData(keys.liked, [post('p1'), other]);
    client.setQueryData(keys.post('p1'), post('p1'));
    client.setQueryData(keys.comments('p1'), { pages: [[comment('c1')]], pageParams: [0] });
    client.setQueryData(outside, feed);

    client.setQueriesData({ queryKey: keys.root }, (data: unknown) =>
      patchPostInRecord(data, 'p1', likeState),
    );

    expect(client.getQueryData(keys.feed)).toEqual({
      ...feed,
      pages: [feed.pages[0], { ...feed.pages[1], posts: [post('p1', likeState)] }],
    });
    expect(client.getQueryData(keys.saved)).toEqual({
      ...saved,
      pages: [{ ...saved.pages[0], items: [post('p1', likeState), other] }],
    });
    expect(client.getQueryData(keys.timeline('owner:all'))).toEqual({
      ...timeline,
      pages: [{ ...timeline.pages[0], items: [entry('p1', { post: post('p1', likeState) })] }],
    });
    expect(client.getQueryData(keys.liked)).toEqual([post('p1', likeState), other]);
    expect(client.getQueryData(keys.post('p1'))).toEqual(post('p1', likeState));
    expect(client.getQueryData(keys.comments('p1'))).toEqual({
      pages: [[comment('c1')]],
      pageParams: [0],
    });
    expect(client.getQueryData(outside)).toEqual(feed);
    expect(feed.pages[1].posts[0].isLiked).toBe(false);
    client.clear();
  });
});

describe('reaction flag semantics (viewer-only)', () => {
  // Regression: the owner's `isReposted` must never be folded into the viewer's `hasReposted`.
  it('keeps timeline ownership flags separate from the viewer render state', () => {
    expect(
      patchPostInRecord({ items: [entry('p1')] }, 'p1', { hasReposted: false, sharesCount: 2 }),
    ).toMatchObject({
      items: [{ isReposted: true, post: { hasReposted: false, sharesCount: 2 } }],
    });
  });
});

describe('patchCommentInPages', () => {
  const likedComment = { isLiked: true, likesCount: 3 };

  it('patches { comments: [] } pages including nested replies', () => {
    expect(
      patchCommentInPages({ comments: [comment('c1', [comment('c2')])] }, 'c2', likedComment),
    ).toMatchObject({
      comments: [{ likesCount: 0, replies: [{ id: 'c2', isLiked: true, likesCount: 3 }] }],
    });
  });

  it('patches plain comment arrays and ignores unknown records', () => {
    expect(patchCommentInPages([comment('c1')], 'c1', likedComment)).toMatchObject({
      0: { isLiked: true },
    });
    expect(patchCommentInPages({ other: 1 }, 'c1', likedComment)).toEqual({ other: 1 });
  });

  it('writes through infinite comment pages including replies and leaves post data alone', () => {
    const client = new QueryClient();
    const keys = socialKeys('viewer');
    const data = {
      pages: [
        [comment('c1')],
        { comments: [comment('c2', [comment('c3')])], nextCursor: 'comments-cursor' },
      ],
      pageParams: [0, 20],
    };
    client.setQueryData(keys.comments('p1'), data);
    client.setQueryData(keys.post('p1'), post('p1'));

    client.setQueriesData({ queryKey: keys.root }, (data: unknown) =>
      patchCommentInPages(data, 'c3', likedComment),
    );
    client.setQueriesData({ queryKey: keys.root }, (data: unknown) =>
      patchCommentInPages(data, 'c1', likedComment),
    );

    expect(client.getQueryData(keys.comments('p1'))).toEqual({
      pages: [
        [{ ...comment('c1'), ...likedComment }],
        {
          comments: [comment('c2', [{ ...comment('c3'), ...likedComment }])],
          nextCursor: 'comments-cursor',
        },
      ],
      pageParams: [0, 20],
    });
    expect(client.getQueryData(keys.post('p1'))).toEqual(post('p1'));
    expect(data.pages).toEqual([
      [comment('c1')],
      { comments: [comment('c2', [comment('c3')])], nextCursor: 'comments-cursor' },
    ]);
    client.clear();
  });
});
