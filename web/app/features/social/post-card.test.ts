import { expect, it } from 'vitest';
import { canRepostPost } from './post-card';

it('does not expose repost for close-friends posts', () => {
  expect(canRepostPost('EVERYONE')).toBe(true);
  expect(canRepostPost('CLOSE_FRIENDS')).toBe(false);
});
