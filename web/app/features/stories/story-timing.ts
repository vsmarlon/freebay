export function shouldAutoAdvanceStory(ready: boolean, paused: boolean): boolean {
  return ready && !paused;
}

export function storyAdvanceDelayMs(
  mediaType: 'IMAGE' | 'VIDEO',
  videoDurationMs?: number,
): number {
  return mediaType === 'VIDEO' &&
    videoDurationMs &&
    Number.isFinite(videoDurationMs) &&
    videoDurationMs > 0
    ? videoDurationMs
    : 7000;
}

export function isCurrentStoryReady(
  storyId: string | undefined,
  readyStoryId: string | undefined,
): boolean {
  return Boolean(storyId && storyId === readyStoryId);
}
