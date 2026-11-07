import { useCallback, useRef, useSyncExternalStore, useState } from 'react';
import { decode as decodeBlurHash } from 'blurhash';
import { usePreferences } from '../../core/preferences';
import { useMediaUrl, mediaUrl } from '../../core/media';
import { useI18n } from '../../core/locale';
import { trackVideo } from '../../core/in-view';
import { Icon } from '../../components';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import type { PostMediaItem } from './types';

const catalogs = { en, 'pt-BR': ptBR };
const safeUrl = (src: string | null | undefined): string | undefined => {
  if (!src) return undefined;
  try {
    return mediaUrl(src);
  } catch {
    return undefined;
  }
};
const isPrivateUrl = (src: string) => src.startsWith('/media/');

function BlurHashPlaceholder({ hash, className }: { hash: string; className: string }) {
  const draw = useCallback((canvas: HTMLCanvasElement | null) => {
    if (!canvas) return;
    try {
      const pixels = decodeBlurHash(hash, 32, 32);
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      const image = ctx.createImageData(32, 32);
      image.data.set(pixels);
      ctx.putImageData(image, 0, 0);
    } catch { /* invalid hash — leave the canvas blank */ }
  }, [hash]);
  return <canvas ref={draw} width={32} height={32} aria-hidden="true" className={className} />;
}

function SlidePlaceholder({ className }: { className: string }) {
  return <div className={`grid place-items-center bg-surface-high text-muted ${className}`} aria-hidden="true"><Icon name="sell" size={28} /></div>;
}

const fullscreenSubscribe = (onChange: () => void) => {
  document.addEventListener('fullscreenchange', onChange);
  return () => document.removeEventListener('fullscreenchange', onChange);
};
const fullscreenServerSnapshot = () => null;
const fullscreenSnapshot = () => (typeof document === 'undefined' ? null : document.fullscreenElement);
type WebkitFullscreenVideo = HTMLVideoElement & { webkitEnterFullscreen?: () => void };

function FeedVideo({ src, poster, blurHash, label, fullscreenLabel, onToggleSound, soundOn }: { src: string; poster?: string; blurHash?: string; label: string; fullscreenLabel: string; soundOn: boolean; onToggleSound: () => void }) {
  const { t } = useI18n(catalogs);
  const ref = useRef<HTMLVideoElement>(null);
  const setRefs = useCallback((element: HTMLVideoElement | null) => {
    ref.current = element;
    return trackVideo(element);
  }, []);
  const fullscreenElement = useSyncExternalStore(fullscreenSubscribe, fullscreenSnapshot, fullscreenServerSnapshot);
  const isFullscreen = fullscreenElement === ref.current;
  const togglePlay = () => {
    const video = ref.current;
    if (!video) return;
    if (video.paused) void video.play().catch(() => { /* blocked — stays paused */ });
    else video.pause();
  };
  const enterFullscreen = () => {
    const video = ref.current as WebkitFullscreenVideo | null;
    if (!video) return;
    if (typeof video.requestFullscreen === 'function') void video.requestFullscreen().catch(() => { /* blocked */ });
    else video.webkitEnterFullscreen?.();
  };
  return (
    <div className="relative h-full w-full overflow-hidden bg-surface-high">
      {blurHash ? <BlurHashPlaceholder hash={blurHash} className="absolute inset-0 h-full w-full" /> : null}
      <video
        ref={setRefs}
        className="relative h-full w-full object-cover"
        src={src}
        poster={poster}
        muted={!soundOn}
        loop
        playsInline
        preload="metadata"
        controls={isFullscreen}
        onClick={togglePlay}
        aria-label={label}
      />
      <div className="absolute right-3 bottom-3 flex gap-2">
        <button type="button" className="post-video-btn" onClick={onToggleSound} aria-pressed={soundOn} aria-label={soundOn ? t('social.post.muteFeed') : t('social.post.unmuteFeed')}>
          <Icon name={soundOn ? 'volumeOn' : 'volumeOff'} size={17} />
        </button>
        <button type="button" className="post-video-btn" onClick={enterFullscreen} aria-label={fullscreenLabel}>
          <Icon name="maximize" size={17} />
        </button>
      </div>
    </div>
  );
}

function PublicSlide({ item, alt, fullscreenLabel, playLabel, soundOn, onToggleSound }: { item: PostMediaItem; alt: string; fullscreenLabel: string; playLabel: string; soundOn: boolean; onToggleSound: () => void }) {
  const src = safeUrl(item.url);
  if (!src) return <SlidePlaceholder className="h-full w-full" />;
  if (item.type === 'IMAGE') return <BlurImage src={src} alt={alt} blurHash={item.blurHash} className="h-full w-full object-cover" />;
  return <FeedVideo src={src} poster={safeUrl(item.thumbnailUrl)} blurHash={item.blurHash} label={playLabel} fullscreenLabel={fullscreenLabel} soundOn={soundOn} onToggleSound={onToggleSound} />;
}

function PrivateSlide({ item, alt, fullscreenLabel, playLabel, soundOn, onToggleSound }: { item: PostMediaItem; alt: string; fullscreenLabel: string; playLabel: string; soundOn: boolean; onToggleSound: () => void }) {
  const isVideo = item.type === 'VIDEO';
  const media = useMediaUrl(item.url, true);
  const thumb = useMediaUrl(item.thumbnailUrl ?? null, isVideo);
  if (media.error) return <SlidePlaceholder className="h-full w-full" />;
  if (!media.url) return <SlidePlaceholder className="h-full w-full" />;
  if (item.type === 'IMAGE') return <BlurImage src={media.url} alt={alt} blurHash={item.blurHash} className="h-full w-full object-cover" />;
  return <FeedVideo src={media.url} poster={thumb.url ?? undefined} blurHash={item.blurHash} label={playLabel} fullscreenLabel={fullscreenLabel} soundOn={soundOn} onToggleSound={onToggleSound} />;
}

function BlurImage({ src, alt, blurHash, className }: { src: string; alt: string; blurHash?: string; className: string }) {
  const [loaded, setLoaded] = useState(false);
  return (
    <div className="relative h-full w-full overflow-hidden">
      {blurHash ? <BlurHashPlaceholder hash={blurHash} className="absolute inset-0 h-full w-full" /> : null}
      <img src={src} alt={alt} loading="lazy" onLoad={() => setLoaded(true)} className={`relative h-full w-full object-cover transition-opacity duration-300 ${loaded ? 'opacity-100' : 'opacity-0'} ${className}`} />
    </div>
  );
}

export function PostMediaCarousel({ items, fallbackAlt }: { items: PostMediaItem[]; fallbackAlt: string }) {
  const { t } = useI18n(catalogs);
  const { feedSoundOn, setFeedSoundOn } = usePreferences();
  if (items.length === 0) return null;
  const toggleSound = () => setFeedSoundOn(!feedSoundOn);
  const sorted = [...items].sort((first, second) => first.order - second.order);
  return (
    <div className="post-media-carousel" role="group">
      {sorted.map((item) => {
        const alt = item.altText ?? fallbackAlt;
        const shared = { item, alt, fullscreenLabel: t('social.post.fullscreen'), playLabel: t('social.post.playVideo'), soundOn: feedSoundOn, onToggleSound: toggleSound };
        return (
          <div className="post-media-slide" key={item.id}>
            {isPrivateUrl(item.url) ? <PrivateSlide {...shared} /> : <PublicSlide {...shared} />}
          </div>
        );
      })}
    </div>
  );
}
