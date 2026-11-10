import { useEffect, useRef, type Dispatch, type SetStateAction } from 'react';
import { storiesApi } from '../api';
import { shouldAutoAdvanceStory, storyAdvanceDelayMs } from '../story-timing';

/**
 * View tracking, keyboard navigation and the auto-advance timer share one
 * effect per story so a pause keeps the remaining time (the bar and the slide
 * stay in step).
 */
export function useStoryPlayback({
  storyId,
  storyMediaType,
  ready,
  inactive,
  index,
  move,
  closeViewer,
  setPaused,
}: {
  storyId: string | undefined;
  storyMediaType: string | undefined;
  ready: boolean;
  inactive: boolean;
  index: number;
  move: (index: number) => void;
  closeViewer: () => void;
  setPaused: Dispatch<SetStateAction<boolean>>;
}) {
  const remainingRef = useRef<number | null>(null);
  const remainingStoryRef = useRef<string | undefined>(undefined);
  const viewed = useRef(new Set<string>());

  useEffect(() => {
    if (!storyId) return;
    if (ready && !viewed.current.has(storyId)) {
      viewed.current.add(storyId);
      void storiesApi.view(storyId).catch(() => {});
    }
    if (remainingStoryRef.current !== storyId) {
      remainingStoryRef.current = storyId;
      remainingRef.current = null;
    }
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'ArrowLeft') move(index - 1);
      else if (event.key === 'ArrowRight') move(index + 1);
      else if (event.key === 'Escape') closeViewer();
      else if (event.key === ' ') {
        event.preventDefault();
        setPaused((state) => !state);
      }
    };
    window.addEventListener('keydown', onKey);
    let timer: number | undefined;
    let cleanupTimer = () => {};
    if (storyMediaType !== 'VIDEO' && shouldAutoAdvanceStory(ready, inactive)) {
      const remaining = remainingRef.current ?? storyAdvanceDelayMs('IMAGE');
      const started = Date.now();
      timer = window.setTimeout(() => move(index + 1), remaining);
      // pause keeps the remaining time so the bar and the slide stay in step
      cleanupTimer = () => {
        if (timer) window.clearTimeout(timer);
        remainingRef.current = Math.max(0, remaining - (Date.now() - started));
      };
    }
    return () => {
      cleanupTimer();
      window.removeEventListener('keydown', onKey);
    };
  }, [storyId, storyMediaType, ready, inactive, index, move, closeViewer, setPaused]);
}
