import { expect, it } from 'vitest';
import { findMention, replaceMention } from './mentions';

it('recognizes a mention only immediately before the caret', () => {
  expect(findMention('hi @mar and text', 7)).toEqual({ start: 3, term: 'mar' });
  expect(findMention('hi @mar and text', 16)).toBeNull();
});

it('replaces the mention without losing text after the caret', () => {
  expect(
    replaceMention(
      'hi @mar and text',
      { start: 3, term: 'mar' },
      { username: 'marlon', displayName: 'Marlon' },
    ),
  ).toBe('hi @marlon  and text');
});
