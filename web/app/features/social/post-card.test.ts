import { expect, it } from 'vitest';
import { canRepostPost } from './post-card';
import { orderedMedia } from './post-media';
import type { PostMediaItem } from './types';

const media = (id: string, order: number): PostMediaItem => ({
  id,
  url: `/uploads/${id}.jpg`,
  thumbnailUrl: null,
  type: 'IMAGE',
  altText: null,
  order,
});

it('does not expose repost for close-friends posts', () => {
  expect(canRepostPost('EVERYONE')).toBe(true);
  expect(canRepostPost('CLOSE_FRIENDS')).toBe(false);
});

it('renders the ordered media contract', () => {
  expect(orderedMedia([media('second', 1), media('first', 0)]).map((item) => item.id)).toEqual([
    'first',
    'second',
  ]);
});
