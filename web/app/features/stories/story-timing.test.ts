import { expect, it } from 'vitest';
import { isCurrentStoryReady, shouldAutoAdvanceStory, storyAdvanceDelayMs } from './story-timing';

it('advances only after media is ready and while unpaused, including reduced-motion mode', () => {
  expect(shouldAutoAdvanceStory(false, false)).toBe(false);
  expect(shouldAutoAdvanceStory(true, true)).toBe(false);
  expect(shouldAutoAdvanceStory(true, false)).toBe(true);
});

it('uses image timing and the loaded video duration, and ignores readiness from the previous story', () => {
  expect(storyAdvanceDelayMs('IMAGE')).toBe(7000);
  expect(storyAdvanceDelayMs('VIDEO', 12500)).toBe(12500);
  expect(storyAdvanceDelayMs('VIDEO', 0)).toBe(7000);
  expect(isCurrentStoryReady('next', 'previous')).toBe(false);
  expect(isCurrentStoryReady('next', 'next')).toBe(true);
});
