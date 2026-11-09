import { expect, it } from 'vitest';
import { trimWindow, trimmedFileName } from './video-editor';

it('clamps the trim into the video and ignores windows shorter than 0.2s', () => {
  expect(trimWindow(2, 5, 10)).toEqual({ start: 2, end: 5, changed: true });
  expect(trimWindow(2, 1, 10)).toEqual({ start: 0, end: 10, changed: false });
  expect(trimWindow(-3, 20, 10)).toEqual({ start: 0, end: 10, changed: false });
  expect(trimWindow(1.9, 2.0, 10)).toEqual({ start: 0, end: 10, changed: false });
  expect(trimWindow(0.04, 9.96, 10)).toEqual({ start: 0, end: 10, changed: false }); // sub-frame identity stays untrimmed
  expect(trimWindow(0.1, 10, 10)).toEqual({ start: 0.1, end: 10, changed: true });   // any real head cut is a trim
  expect(trimWindow(2, 5, NaN)).toEqual({ start: 0, end: 0, changed: false }); // unknown duration keeps original
});

it('names the trimmed mp4 export after the source', () => {
  expect(trimmedFileName('clip.webm', 'video/mp4')).toBe('clip-trimmed.mp4');
  expect(trimmedFileName('clip.mp4', 'video/webm')).toBe('clip-trimmed.webm');
  expect(trimmedFileName('.mp4', 'video/webm')).toBe('story-trimmed.webm');
});
