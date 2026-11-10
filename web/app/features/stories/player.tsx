import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from 'react';
import type { PointerEvent as ReactPointerEvent } from 'react';
import { useNavigate } from 'react-router';
import { storiesApi } from './api';
import { isCurrentStoryReady, shouldAutoAdvanceStory, storyAdvanceDelayMs } from './story-timing';
import { StoryTextOverlays } from './text-block-editor';
import { Avatar, Media, storyAge, useStoryCopy, type Story, type User } from './shared';

const subscribeVisibility = (callback: () => void) => {
  document.addEventListener('visibilitychange', callback);
  return () => document.removeEventListener('visibilitychange', callback);
};
const isDocumentVisible = () => document.visibilityState === 'visible';
const serverDocumentVisible = () => true;
function useDocumentVisible() {
  return useSyncExternalStore(subscribeVisibility, isDocumentVisible, serverDocumentVisible);
}

// ponytail: one player for stories and highlights so both routes keep the same app behavior.
export function StoryPlayer({
  stories,
  title,
  user,
  error,
  retry,
  loading,
}: {
  stories: Story[];
  title?: string;
  user?: User;
  error?: boolean;
  retry?: () => void;
  loading?: boolean;
}) {
  const navigate = useNavigate();
  const { path, t } = useStoryCopy();
  const visible = useDocumentVisible();
  const [index, setIndex] = useState(0);
  const [readyMedia, setReadyMedia] = useState<{ storyId: string; durationMs?: number }>();
  const [failedMediaId, setFailedMediaId] = useState<string>();
  const [paused, setPaused] = useState(false);
  const [dragOffset, setDragOffset] = useState(0);
  const [dragging, setDragging] = useState(false);
  const dragOffsetRef = useRef(0);
  const dragRef = useRef<{ x: number; y: number; active: boolean } | null>(null);
  const remainingRef = useRef<number | null>(null);
  const remainingStoryRef = useRef<string | undefined>(undefined);
  const viewed = useRef(new Set<string>());
  const story = stories[index];
  const inactive = paused || !visible;
  const ready = isCurrentStoryReady(story?.id, readyMedia?.storyId) && failedMediaId !== story?.id;
  const headerUser = user ?? story?.user;
  const storyId = story?.id;
  const storyMediaType = story?.mediaType;

  const closeViewer = useCallback(() => {
    const historyIndex = typeof window === 'undefined' ? undefined : window.history.state?.idx;
    if (typeof historyIndex === 'number' && historyIndex > 0) navigate(-1);
    else navigate(path('feed'));
  }, [navigate, path]);
  // The only writer of `index`; per-story UI resets ride this event instead of a
  // render-phase state adjustment.
  const move = useCallback(
    (next: number) => {
      if (next < 0 || next >= stories.length) {
        closeViewer();
        return;
      }
      setPaused(false);
      dragOffsetRef.current = 0;
      setDragOffset(0);
      setIndex(next);
    },
    [closeViewer, stories.length],
  );
  const setDrag = (value: number) => {
    dragOffsetRef.current = value;
    setDragOffset(value);
  };
  const onPointerDown = (event: ReactPointerEvent<HTMLElement>) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if ((event.target as HTMLElement).closest('button,a')) return;
    dragRef.current = { x: event.clientX, y: event.clientY, active: false };
    event.currentTarget.setPointerCapture(event.pointerId);
    setPaused(true);
  };
  const onPointerMove = (event: ReactPointerEvent<HTMLElement>) => {
    const start = dragRef.current;
    if (!start) return;
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    if (!start.active) {
      if (dy <= 8 || dy <= Math.abs(dx)) return;
      start.active = true;
      setDragging(true);
    }
    setDrag(Math.max(0, dy));
  };
  const onPointerUp = (event: ReactPointerEvent<HTMLElement>) => {
    const start = dragRef.current;
    dragRef.current = null;
    setDragging(false);
    // ponytail: distance threshold only; velocity-aware dismissal if drag feels wrong
    if (
      start?.active &&
      dragOffsetRef.current > (typeof window === 'undefined' ? 0 : window.innerHeight * 0.25)
    ) {
      closeViewer();
      return;
    }
    setDrag(0);
    setPaused(false);
    if (event.currentTarget.hasPointerCapture(event.pointerId))
      event.currentTarget.releasePointerCapture(event.pointerId);
  };

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
  }, [storyId, storyMediaType, ready, inactive, index, move, closeViewer]);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title ?? headerUser?.displayName ?? t.title}
      className="fixed inset-0 z-50 grid place-items-center overscroll-contain bg-black text-white"
    >
      <section
        className="relative size-full touch-none select-none overflow-hidden bg-black"
        style={{
          transform: dragOffset ? `translateY(${dragOffset}px)` : undefined,
          transition: dragging ? 'none' : 'transform 180ms linear',
        }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
      >
        <div className="pointer-events-none absolute inset-x-0 top-0 z-0 h-28 bg-linear-to-b from-black/70 to-transparent" />
        {error ? (
          <div className="grid h-full place-items-center">
            <div role="alert" className="space-y-4 text-center text-white">
              <p>{t.error}</p>
              {retry ? (
                <button className="underline" onClick={retry}>
                  {t.retry}
                </button>
              ) : null}
            </div>
          </div>
        ) : !story ? (
          <p className="p-8 text-white" aria-live="polite">
            {loading ? t.loading : t.unavailable}
          </p>
        ) : (
          <>
            <button
              type="button"
              className="absolute right-3 top-3 z-30 grid size-10 place-items-center bg-black/45 text-white"
              onClick={closeViewer}
              aria-label={t.closeViewer}
            >
              ×
            </button>
            <div className="absolute inset-x-3 top-3 z-20 flex gap-1" aria-hidden="true">
              {stories.map((entry, position) => (
                <span key={entry.id} className="h-1 flex-1 bg-white/30">
                  <span
                    className={`block h-full origin-left bg-white ${position < index ? 'scale-x-100' : position === index && ready ? `animate-story-progress motion-reduce:animate-none ${inactive ? '[animation-play-state:paused]' : ''}` : ''}`}
                    style={{
                      animationDuration: `${storyAdvanceDelayMs(entry.mediaType, readyMedia?.storyId === entry.id ? readyMedia.durationMs : undefined)}ms`,
                    }}
                  />
                </span>
              ))}
            </div>
            <header className="absolute inset-x-3 top-7 z-20 flex items-center gap-3 text-white">
              {headerUser ? <Avatar user={headerUser} className="size-9" /> : null}
              <div className="min-w-0 flex-1">
                <p className="truncate font-bold">{title ?? headerUser?.displayName}</p>
                <p className="flex items-center gap-2 text-xs text-white/75">
                  {title && headerUser ? (
                    <span className="truncate">{headerUser.displayName}</span>
                  ) : null}
                  {story.audience === 'CLOSE_FRIENDS' ? (
                    <span className="text-success">{t.closeFriends}</span>
                  ) : null}
                  <time dateTime={story.createdAt}>{storyAge(story.createdAt, t.now)}</time>
                  {story.viewsCount !== undefined ? (
                    <span aria-hidden="true">
                      · {story.viewsCount} {t.views}
                    </span>
                  ) : null}
                </p>
              </div>
            </header>
            <Media
              key={story.id}
              story={story}
              enabled
              paused={inactive}
              controls={false}
              className="absolute inset-0 size-full object-contain"
              onReady={(durationMs) => setReadyMedia({ storyId: story.id, durationMs })}
              onPlaybackState={(playing) => setPaused(!playing)}
              onEnded={() => move(index + 1)}
              onError={() => setFailedMediaId(story.id)}
            />
            <button
              aria-label={t.previous}
              className="absolute inset-y-16 left-0 z-10 w-1/3"
              onClick={() => move(index - 1)}
            />
            <button
              aria-label={t.next}
              className="absolute inset-y-16 right-0 z-10 w-1/3"
              onClick={() => move(index + 1)}
            />
            {failedMediaId === story.id ? (
              <p
                role="alert"
                className="absolute inset-x-4 top-24 z-20 bg-surface-high p-3 text-ink"
              >
                {t.mediaError}
              </p>
            ) : null}
            {story.caption ? (
              <p className="absolute inset-x-4 bottom-5 z-10 text-center text-white [text-shadow:0_1px_3px_#000]">
                {story.caption}
              </p>
            ) : null}
            <StoryTextOverlays blocks={story.textBlocks ?? []} />
            {!ready ? (
              <span className="sr-only" aria-live="polite">
                {t.loading}
              </span>
            ) : null}
            {inactive ? (
              <span className="absolute bottom-16 left-1/2 z-10 -translate-x-1/2 bg-black/45 px-3 py-2 text-white">
                {t.paused}
              </span>
            ) : null}
          </>
        )}
      </section>
    </div>
  );
}
