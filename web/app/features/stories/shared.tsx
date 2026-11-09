import { useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../../core/api';
import { useI18n } from '../../core/locale';
import { useMediaUrl } from '../../core/media';
import { useSession } from '../../core/session';
import { type StoryTextBlock } from './text-block-editor';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

export type User = {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  isVerified?: boolean;
};
export type Story = {
  id: string;
  userId?: string;
  imageUrl: string;
  mediaType: 'IMAGE' | 'VIDEO';
  audience: 'EVERYONE' | 'CLOSE_FRIENDS';
  caption: string | null;
  textBlocks: StoryTextBlock[];
  createdAt: string;
  expiresAt: string;
  viewsCount?: number;
  user?: User;
};
export type Group = { user: User; stories: Story[] };
export type Highlight = {
  id: string;
  title: string;
  user: User;
  coverStoryId: string;
  coverUrl: string;
  stories: Story[];
};
export type Feed = { stories: Group[]; userHasStory: boolean };

const copy = { en, 'pt-BR': ptBR };
export const privateMediaPath = (src: string) => {
  if (src.startsWith('/media/story/') || /^https?:\/\//.test(src)) return src;
  const name = src.split('?')[0].split('/').pop();
  return name ? `/media/story/${encodeURIComponent(name)}` : '';
};

// Locale-bound copy helper so split route files repeat one binding instead of
// the ternary: `const { locale, path, t } = useStoryCopy()`.
export function useStoryCopy() {
  const { locale, path } = useI18n(copy);
  return { locale, path, t: locale === 'en' ? copy.en : copy['pt-BR'] };
}

export function storyAge(createdAt: string | undefined, nowLabel: string) {
  if (!createdAt) return '';
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000));
  if (minutes < 1) return nowLabel;
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
}

export function useStories<T>(path: string, key: string) {
  const { user } = useSession();
  const query = useQuery<T>({
    queryKey: ['stories', path, key, user?.id],
    queryFn: ({ signal }) => api.get<T>(path, { signal }),
    retry: false,
  });
  return { value: query.data, error: query.isError, retry: () => void query.refetch() };
}

export function Media({
  story,
  enabled,
  paused = false,
  autoPlay,
  controls,
  className = '',
  onReady,
  onError,
  onEnded,
  onPlaybackState,
}: {
  story: Story;
  enabled: boolean;
  paused?: boolean;
  autoPlay?: boolean;
  controls?: boolean;
  className?: string;
  onReady?: (durationMs?: number) => void;
  onError?: () => void;
  onEnded?: () => void;
  onPlaybackState?: (playing: boolean) => void;
}) {
  const { user } = useSession();
  const play = autoPlay ?? Boolean(onEnded);
  const showControls = controls ?? Boolean(onEnded);
  return (
    <PrivateStoryMedia
      key={`${story.id}:${user?.id ?? ''}`}
      story={story}
      enabled={enabled && Boolean(user)}
      paused={paused}
      autoPlay={play}
      controls={showControls}
      className={className}
      onReady={onReady}
      onError={onError}
      onEnded={onEnded}
      onPlaybackState={onPlaybackState}
    />
  );
}

function PrivateStoryMedia({
  story,
  enabled,
  paused,
  autoPlay,
  controls,
  className,
  onReady,
  onError,
  onEnded,
  onPlaybackState,
}: {
  story: Story;
  enabled: boolean;
  paused: boolean;
  autoPlay: boolean;
  controls: boolean;
  className: string;
  onReady?: (durationMs?: number) => void;
  onError?: () => void;
  onEnded?: () => void;
  onPlaybackState?: (playing: boolean) => void;
}) {
  const { t } = useStoryCopy();
  const { url, isPending, error } = useMediaUrl(privateMediaPath(story.imageUrl), enabled);
  const videoRef = useCallback(
    (video: HTMLVideoElement | null) => {
      if (!video || !autoPlay) return;
      if (paused) video.pause();
      else void video.play().catch(() => {});
    },
    [paused, autoPlay],
  );
  if (error)
    return (
      <div
        role="alert"
        className="grid h-full place-items-center bg-surface-mid p-6 text-center text-ink-muted"
      >
        {t.permission}
      </div>
    );
  if (!url)
    return (
      <div
        aria-label={t.loading}
        className={`h-full bg-surface-mid ${isPending ? 'animate-pulse' : ''}`}
      />
    );
  return story.mediaType === 'VIDEO' ? (
    <video
      ref={videoRef}
      className={className}
      src={url}
      controls={controls}
      playsInline
      autoPlay={autoPlay}
      preload={autoPlay ? 'auto' : 'metadata'}
      onLoadedData={(event) => onReady?.(event.currentTarget.duration * 1000)}
      onPlay={() => onPlaybackState?.(true)}
      onPause={() => onPlaybackState?.(false)}
      onEnded={onEnded}
      onError={onError}
    />
  ) : (
    <img
      className={className}
      src={url}
      alt={story.caption ?? ''}
      onLoad={() => onReady?.()}
      onError={onError}
    />
  );
}

export function Avatar({ user, className = '' }: { user: User; className?: string }) {
  return (
    <span
      className={`grid aspect-square shrink-0 place-items-center overflow-hidden bg-surface-high text-ink ${className}`}
      aria-label={user.displayName}
    >
      {user.avatarUrl ? (
        <img className="size-full object-cover" src={user.avatarUrl} alt="" />
      ) : (
        user.displayName.slice(0, 1).toUpperCase()
      )}
    </span>
  );
}
