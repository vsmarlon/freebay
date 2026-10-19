import { describe, expect, it, vi } from 'vitest';
import { searchPage, socialApi } from './data';
import { api } from '../../core/api';
import { canApproveComment, type Post } from './types';

const post = (id: string): Post => ({ id, userId: 'owner', content: id, imageUrl: null, type: 'REGULAR', audience: 'EVERYONE', likesCount: 0, commentsCount: 0, sharesCount: 0, isLiked: false, isSaved: false, hasReposted: false, createdAt: '2026-01-01T00:00:00.000Z', user: { id: 'owner', displayName: 'Member' } });

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
