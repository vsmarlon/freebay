import { describe, expect, it } from 'vitest';
import { QueryClient } from '@tanstack/react-query';
import {
  patchCommentRow,
  patchCommentsPage,
  patchCommentViews,
  patchFeedPage,
  patchPostItemPage,
  patchPostList,
  patchPostViews,
  patchPostView,
  patchTimelinePage,
  socialKeys,
} from './queries';
import type {
  Comment,
  CommentsPage,
  CursorPage,
  FeedPage,
  Post,
  SocialUser,
  TimelineEntry,
} from './types';

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

describe('patchPostViews (authoritative mutation merge)', () => {
  it('patches the post inside FeedPage.posts', () => {
    const page: FeedPage = { posts: [post('p1'), post('p2')], hasMore: false, nextCursor: null };
    expect(patchFeedPage(page, 'p2', likeState)).toMatchObject({
      posts: [
        { id: 'p1', isLiked: false },
        { id: 'p2', isLiked: true, likesCount: 4 },
      ],
    });
  });

  it('patches the post inside CursorPage items', () => {
    const page: CursorPage<Post> = { items: [post('p1')], hasMore: false, nextCursor: null };
    expect(patchPostItemPage(page, 'p1', likeState)).toMatchObject({
      items: [{ isLiked: true, likesCount: 4 }],
    });
  });

  it('patches the post inside timeline entries and leaves the owner flag alone', () => {
    const page: CursorPage<TimelineEntry> = {
      items: [entry('p1')],
      hasMore: false,
      nextCursor: null,
    };
    expect(patchTimelinePage(page, 'p1', likeState)).toMatchObject({
      items: [{ post: { isLiked: true, likesCount: 4 }, isReposted: true }],
    });
  });

  it('patches a bare post-detail object and leaves other posts and lists untouched', () => {
    expect(patchPostView(post('p1'), 'p1', likeState)).toMatchObject({
      id: 'p1',
      likesCount: 4,
    });
    const untouched = post('p1');
    expect(patchPostView(untouched, 'other', likeState)).toBe(untouched);
    expect(patchPostList([post('p1')], 'p1', likeState)).toEqual([post('p1', likeState)]);
    const list = [post('p1')];
    expect(patchPostList(list, 'other', likeState)[0]).toBe(list[0]);
  });

  it('patches both the original and the repost copy of one post in a timeline page', () => {
    const page: CursorPage<TimelineEntry> = {
      items: [entry('p1'), entry('p1', { repostId: null, isReposted: false, repostedBy: null })],
      hasMore: false,
      nextCursor: null,
    };
    const patched = patchTimelinePage(page, 'p1', likeState);
    expect(patched.items.map((item) => item.post.likesCount)).toEqual([4, 4]);
    expect(patched.items.map((item) => item.isReposted)).toEqual([true, false]);
    expect(page.items[0].post.isLiked).toBe(false);
  });

  it('writes through every cached view by key without changing pagination or unrelated cache data', () => {
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
    const search = {
      pages: [{ items: [post('p1'), other], hasMore: false, nextCursor: null }],
      pageParams: [undefined],
    };
    const mentionSearch = { users: [{ id: 'u1', displayName: 'Uma' }] satisfies SocialUser[] };
    const outside = socialKeys('other-viewer').feed;
    client.setQueryData(keys.feed, feed);
    client.setQueryData(keys.saved, saved);
    client.setQueryData(keys.timeline('owner:all'), timeline);
    client.setQueryData([...keys.search, 'sun', 'all'], search);
    client.setQueryData(keys.liked, [post('p1'), other]);
    client.setQueryData(keys.post('p1'), post('p1'));
    client.setQueryData(keys.comments('p1'), { pages: [[comment('c1')]], pageParams: [0] });
    client.setQueryData([...keys.root, 'mention-search', 'ma'], mentionSearch);
    client.setQueryData(outside, feed);

    patchPostViews(client, 'viewer', 'p1', likeState);

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
    expect(client.getQueryData([...keys.search, 'sun', 'all'])).toEqual({
      ...search,
      pages: [{ ...search.pages[0], items: [post('p1', likeState), other] }],
    });
    expect(client.getQueryData(keys.liked)).toEqual([post('p1', likeState), other]);
    expect(client.getQueryData(keys.post('p1'))).toEqual(post('p1', likeState));
    expect(client.getQueryData(keys.comments('p1'))).toEqual({
      pages: [[comment('c1')]],
      pageParams: [0],
    });
    expect(client.getQueryData([...keys.root, 'mention-search', 'ma'])).toEqual(mentionSearch);
    expect(client.getQueryData(outside)).toEqual(feed);
    expect(feed.pages[1].posts[0].isLiked).toBe(false);
    client.clear();
  });

  it('does not create a post-detail cache entry for a post that was never cached', () => {
    const client = new QueryClient();
    patchPostViews(client, 'viewer', 'ghost', likeState);
    expect(client.getQueryData(socialKeys('viewer').post('ghost'))).toBeUndefined();
    client.clear();
  });
});

describe('reaction flag semantics (viewer-only)', () => {
  // Regression: the owner's `isReposted` must never be folded into the viewer's `hasReposted`.
  it('keeps timeline ownership flags separate from the viewer render state', () => {
    const page: CursorPage<TimelineEntry> = {
      items: [entry('p1')],
      hasMore: false,
      nextCursor: null,
    };
    expect(patchTimelinePage(page, 'p1', { hasReposted: false, sharesCount: 2 })).toMatchObject({
      items: [{ isReposted: true, post: { hasReposted: false, sharesCount: 2 } }],
    });
  });
});

describe('patchCommentViews', () => {
  const likedComment = { isLiked: true, likesCount: 3 };

  it('patches { comments: [] } pages including nested replies', () => {
    expect(
      patchCommentsPage({ comments: [comment('c1', [comment('c2')])] }, 'c2', likedComment),
    ).toMatchObject({
      comments: [{ likesCount: 0, replies: [{ id: 'c2', isLiked: true, likesCount: 3 }] }],
    });
  });

  it('patches plain comment arrays and leaves unmatched rows by reference', () => {
    expect(patchCommentsPage([comment('c1')], 'c1', likedComment)).toMatchObject({
      0: { isLiked: true },
    });
    const leaf = comment('c1');
    const leaves = patchCommentsPage([leaf], 'missing', likedComment);
    expect(Array.isArray(leaves) && leaves[0]).toBe(leaf);
    // A parent row is rebuilt to hold its replies, but the untouched reply keeps its identity.
    const reply = comment('c2');
    const rebuilt = patchCommentsPage([comment('c1', [reply])], 'missing', likedComment);
    expect(Array.isArray(rebuilt) && rebuilt[0].replies[0]).toBe(reply);
  });

  it('reaches a reply nested three levels deep without flattening the chain', () => {
    const page: CommentsPage = {
      comments: [comment('c1', [comment('c2', [comment('c3', [comment('c4')])])])],
    };
    expect(patchCommentsPage(page, 'c4', likedComment)).toMatchObject({
      comments: [
        {
          id: 'c1',
          replies: [
            {
              id: 'c2',
              replies: [{ id: 'c3', replies: [{ id: 'c4', isLiked: true, likesCount: 3 }] }],
            },
          ],
        },
      ],
    });
    expect(patchCommentRow(comment('c1'), 'c1', likedComment).likesCount).toBe(3);
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

    patchCommentViews(client, 'viewer', 'c3', likedComment);
    patchCommentViews(client, 'viewer', 'c1', likedComment);

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
