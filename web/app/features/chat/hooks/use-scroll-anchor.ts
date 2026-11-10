import { useEffect, useRef } from 'react';

/**
 * Keeps the transcript pinned to the bottom, and restores the viewport offset
 * trimmed by prepending older pages (the caller captures the height first).
 */
export function useScrollAnchor(messageCount: number) {
  const scrollNodeRef = useRef<HTMLDivElement | null>(null);
  const previousHeight = useRef<number | null>(null);

  useEffect(() => {
    const scroll = scrollNodeRef.current;
    if (!scroll) return;
    if (previousHeight.current !== null) {
      scroll.scrollTop += scroll.scrollHeight - previousHeight.current;
      previousHeight.current = null;
    } else scroll.scrollTop = scroll.scrollHeight;
  }, [messageCount]);

  return {
    scrollNodeRef,
    capture: () => {
      previousHeight.current = scrollNodeRef.current?.scrollHeight ?? 0;
    },
  };
}
