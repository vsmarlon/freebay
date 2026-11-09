import { describe, expect, it, vi } from 'vitest';
import { searchPage, socialApi } from './data';
import { api } from '../../core/api';
import { canApproveComment, type Post } from './types';

const post = (id: string): Post => ({ id, userId: 'owner', content: id, media: [], type: 'REGULAR', audience: 'EVERYONE', likesCount: 0, commentsCount: 0, sharesCount: 0, isLiked: false, isSaved: false, hasReposted: false, createdAt: '2026-01-01T00:00:00.000Z', user: { id: 'owner', displayName: 'Member' } });

describe('post search cursor adapter', () => {
  it('uses the server array boundary to continue full pages and stops short pages', () => {
    const full = searchPage(Array.from({ length: 20 }, (_, index) => post(String(index))));
    expect(full).toMatchObject({ hasMore: true, nextCursor: '19', items: expect.any(Array) });
    expect(searchPage([post('last')])).toEqual({ items: [post('last')], hasMore: false, nextCursor: null });
    expect(searchPage([])).toEqual({ items: [], hasMore: false, nextCursor: null });
  });
});

describe('restricted comment approval visibility', () => {
  const comment = { id: 'comment-1', postId: 'post-1', userId: 'author', content: 'pending', createdAt: '', likesCount: 0, isLiked: false, replies: [], isHidden: true };

  it('is available only to the post owner for a hidden comment with a visible parent', () => {
    expect(canApproveComment(comment, 'owner', 'owner', false)).toBe(true);
    expect(canApproveComment(comment, 'owner', 'author', false)).toBe(false);
    expect(canApproveComment({ ...comment, isHidden: false }, 'owner', 'owner', false)).toBe(false);
    expect(canApproveComment(comment, 'owner', 'owner', true)).toBe(false);
  });

  it('uses the existing single-comment approval endpoint', async () => {
    const patch = vi.spyOn(api, 'patch').mockResolvedValue(undefined);
    await socialApi.approveComment('comment/1');
    expect(patch).toHaveBeenCalledWith('/social/comments/comment%2F1/approve');
    patch.mockRestore();
  });
});

describe('social mutation endpoints', () => {
  // Regression: like/repost now return the authoritative { active, count } state
  // that the cache merge uses; an "active" post flips to the PATCH (deactivate) verb.
  it('sends POST for activating and PATCH with the { active, count } payload for deactivating', async () => {
    const post = vi.spyOn(api, 'post').mockResolvedValue({ active: true, count: 5 });
    const patch = vi.spyOn(api, 'patch').mockResolvedValue({ active: false, count: 4 });

    await expect(socialApi.likePost('p1', false)).resolves.toEqual({ active: true, count: 5 });
    expect(post).toHaveBeenCalledWith('/social/posts/p1/like');
    await expect(socialApi.likePost('p1', true)).resolves.toEqual({ active: false, count: 4 });
    expect(patch).toHaveBeenCalledWith('/social/posts/p1/unlike');
    await expect(socialApi.repost('p1', false)).resolves.toEqual({ active: true, count: 5 });
    expect(post).toHaveBeenCalledWith('/social/posts/p1/share');
    await expect(socialApi.likeComment('c1', true)).resolves.toEqual({ active: false, count: 4 });
    expect(patch).toHaveBeenCalledWith('/social/comments/c1/unlike');
    patch.mockResolvedValueOnce({ active: false });
    await expect(socialApi.save('p1', true)).resolves.toEqual({ active: false });
    expect(patch).toHaveBeenCalledWith('/social/posts/p1/unsave');

    post.mockRestore();
    patch.mockRestore();
  });

  it('stamps an idempotency key on comment creation', async () => {
    const post = vi.spyOn(api, 'post').mockResolvedValue({ id: 'c2', postId: 'p1', userId: 'u', content: 'x', createdAt: '', commentsCount: 2 });
    await socialApi.createComment('p1', 'x');
    expect(post).toHaveBeenCalledWith('/social/posts/p1/comments', expect.objectContaining({ content: 'x', clientRequestId: expect.any(String) }));
    post.mockRestore();
  });
});
