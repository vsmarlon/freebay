import { useCallback, useEffect, useRef, useState } from 'react';
import { decode as decodeBlurHash } from 'blurhash';
import { usePreferences } from '../../core/preferences';
import { useMediaUrl, mediaUrl } from '../../core/media';
import { useI18n } from '../../core/locale';
import { trackVideo } from '../../core/in-view';
import { Icon, ImageViewer } from '../../components';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import type { PostMediaItem } from './types';

const catalogs = { en, 'pt-BR': ptBR };
const videoButtonClass =
  'grid size-9 cursor-pointer place-items-center border border-white/25 bg-[#11100ecc] text-white backdrop-blur-[2px] hover:bg-[#11100eee]';
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
  const draw = useCallback(
    (canvas: HTMLCanvasElement | null) => {
      if (!canvas) return;
      try {
        const pixels = decodeBlurHash(hash, 32, 32);
        const ctx = canvas.getContext('2d');
        if (!ctx) return;
        const image = ctx.createImageData(32, 32);
        image.data.set(pixels);
        ctx.putImageData(image, 0, 0);
      } catch {
        /* invalid hash — leave the canvas blank */
      }
    },
    [hash],
  );
  return <canvas ref={draw} width={32} height={32} aria-hidden="true" className={className} />;
}

function SlidePlaceholder({ className }: { className: string }) {
  return (
    <div
      className={`grid place-items-center bg-surface-high text-muted ${className}`}
      aria-hidden="true"
    >
      <Icon name="sell" size={28} />
    </div>
  );
}

type WebkitFullscreenVideo = HTMLVideoElement & { webkitEnterFullscreen?: () => void };

function FeedVideo({
  src,
  poster,
  blurHash,
  label,
  fullscreenLabel,
  onToggleSound,
  soundOn,
}: {
  src: string;
  poster?: string;
  blurHash?: string;
  label: string;
  fullscreenLabel: string;
  soundOn: boolean;
  onToggleSound: () => void;
}) {
  const { t } = useI18n(catalogs);
  const ref = useRef<HTMLVideoElement>(null);
  const setRefs = useCallback((element: HTMLVideoElement | null) => {
    ref.current = element;
    return trackVideo(element);
  }, []);
  // External-system primitive: the fullscreen API is the only source of truth;
  // reading ref.current during render is forbidden, so the listener owns state.
  const [isFullscreen, setIsFullscreen] = useState(false);
  useEffect(() => {
    const sync = () => setIsFullscreen(document.fullscreenElement === ref.current);
    sync();
    document.addEventListener('fullscreenchange', sync);
    return () => document.removeEventListener('fullscreenchange', sync);
  }, []);
  const togglePlay = () => {
    const video = ref.current;
    if (!video) return;
    if (video.paused)
      void video.play().catch(() => {
        /* blocked — stays paused */
      });
    else video.pause();
  };
  const enterFullscreen = () => {
    const video = ref.current as WebkitFullscreenVideo | null;
    if (!video) return;
    if (typeof video.requestFullscreen === 'function')
      void video.requestFullscreen().catch(() => {
        /* blocked */
      });
    else video.webkitEnterFullscreen?.();
  };
  return (
    <div className="relative size-full  overflow-hidden bg-surface-high">
      {blurHash ? (
        <BlurHashPlaceholder hash={blurHash} className="absolute inset-0 size-full " />
      ) : null}
      <video
        ref={setRefs}
        className="relative size-full  object-cover"
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
        <button
          type="button"
          className={videoButtonClass}
          onClick={onToggleSound}
          aria-pressed={soundOn}
          aria-label={soundOn ? t('social.post.muteFeed') : t('social.post.unmuteFeed')}
        >
          <Icon name={soundOn ? 'volumeOn' : 'volumeOff'} size={17} />
        </button>
        <button
          type="button"
          className={videoButtonClass}
          onClick={enterFullscreen}
          aria-label={fullscreenLabel}
        >
          <Icon name="maximize" size={17} />
        </button>
      </div>
    </div>
  );
}

function PublicSlide({
  item,
  alt,
  fullscreenLabel,
  playLabel,
  soundOn,
  onToggleSound,
}: {
  item: PostMediaItem;
  alt: string;
  fullscreenLabel: string;
  playLabel: string;
  soundOn: boolean;
  onToggleSound: () => void;
}) {
  const src = safeUrl(item.url);
  if (!src) return <SlidePlaceholder className="size-full " />;
  if (item.type === 'IMAGE')
    return (
      <BlurImage src={src} alt={alt} blurHash={item.blurHash} className="size-full  object-cover" />
    );
  return (
    <FeedVideo
      src={src}
      poster={safeUrl(item.thumbnailUrl)}
      blurHash={item.blurHash}
      label={playLabel}
      fullscreenLabel={fullscreenLabel}
      soundOn={soundOn}
      onToggleSound={onToggleSound}
    />
  );
}

function PrivateSlide({
  item,
  alt,
  fullscreenLabel,
  playLabel,
  soundOn,
  onToggleSound,
}: {
  item: PostMediaItem;
  alt: string;
  fullscreenLabel: string;
  playLabel: string;
  soundOn: boolean;
  onToggleSound: () => void;
}) {
  const isVideo = item.type === 'VIDEO';
  const media = useMediaUrl(item.url, true);
  const thumb = useMediaUrl(item.thumbnailUrl ?? null, isVideo);
  if (media.error) return <SlidePlaceholder className="size-full " />;
  if (!media.url) return <SlidePlaceholder className="size-full " />;
  if (item.type === 'IMAGE')
    return (
      <BlurImage
        src={media.url}
        alt={alt}
        blurHash={item.blurHash}
        className="size-full  object-cover"
      />
    );
  return (
    <FeedVideo
      src={media.url}
      poster={thumb.url ?? undefined}
      blurHash={item.blurHash}
      label={playLabel}
      fullscreenLabel={fullscreenLabel}
      soundOn={soundOn}
      onToggleSound={onToggleSound}
    />
  );
}

function BlurImage({
  src,
  alt,
  blurHash,
  className,
}: {
  src: string;
  alt: string;
  blurHash?: string;
  className: string;
}) {
  const [loaded, setLoaded] = useState(false);
  return (
    <div className="relative size-full  overflow-hidden">
      {blurHash ? (
        <BlurHashPlaceholder hash={blurHash} className="absolute inset-0 size-full " />
      ) : null}
      <img
        src={src}
        alt={alt}
        loading="lazy"
        onLoad={() => setLoaded(true)}
        className={`relative size-full  object-cover transition-opacity duration-300 ${loaded ? 'opacity-100' : 'opacity-0'} ${className}`}
      />
    </div>
  );
}

export const orderedMedia = (items: PostMediaItem[]) =>
  [...items].sort((first, second) => first.order - second.order);

export function PostMediaCarousel({
  items,
  fallbackAlt,
}: {
  items: PostMediaItem[];
  fallbackAlt: string;
}) {
  const { t } = useI18n(catalogs);
  const { feedSoundOn, setFeedSoundOn } = usePreferences();
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);
  if (items.length === 0) return null;
  const toggleSound = () => setFeedSoundOn(!feedSoundOn);
  const sorted = orderedMedia(items);
  const publicImages = sorted.flatMap((item, slideIndex) => {
    if (item.type !== 'IMAGE' || isPrivateUrl(item.url)) return [];
    const src = safeUrl(item.url);
    return src ? [{ slideIndex, src, alt: item.altText ?? fallbackAlt }] : [];
  });
  return (
    <>
      <div
        className="flex max-h-[640px] aspect-square snap-x snap-mandatory overflow-x-auto border border-(--edge) bg-surface-high scrollbar-none [&::-webkit-scrollbar]:hidden"
        role="group"
      >
        {sorted.map((item, index) => {
          const alt = item.altText ?? fallbackAlt;
          const shared = {
            item,
            alt,
            fullscreenLabel: t('social.post.fullscreen'),
            playLabel: t('social.post.playVideo'),
            soundOn: feedSoundOn,
            onToggleSound: toggleSound,
          };
          const openIndex = publicImages.findIndex((image) => image.slideIndex === index);
          return (
            <div
              className="relative aspect-square flex-[0_0_100%] snap-start overflow-hidden"
              key={item.id}
            >
              {openIndex >= 0 ? (
                <button
                  type="button"
                  className="block size-full cursor-zoom-in border-0 bg-transparent p-0"
                  onClick={() => setViewerIndex(openIndex)}
                  aria-label={t('social.post.openImage')}
                >
                  <PublicSlide {...shared} />
                </button>
              ) : isPrivateUrl(item.url) ? (
                <PrivateSlide {...shared} />
              ) : (
                <PublicSlide {...shared} />
              )}
            </div>
          );
        })}
      </div>
      {viewerIndex !== null ? (
        <ImageViewer
          items={publicImages.map(({ src, alt }) => ({ src, alt }))}
          index={viewerIndex}
          onIndexChange={setViewerIndex}
          onClose={() => setViewerIndex(null)}
          closeLabel={t('common.close')}
          previousLabel={t('social.post.previousImage')}
          nextLabel={t('social.post.nextImage')}
        />
      ) : null}
    </>
  );
}
