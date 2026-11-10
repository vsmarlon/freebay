import { useRef, useState, type KeyboardEvent } from 'react';
import { Icon } from '../../components';
import { ImageViewer } from '../../components/image-viewer';

type CarouselImage = { id?: string; url: string };

type ImageCarouselProps = {
  images: CarouselImage[];
  alt: (index: number) => string;
  label: string;
  noImage: string;
  previousLabel: string;
  nextLabel: string;
  imageLabel: (index: number) => string;
  openLabel: (index: number) => string;
  closeLabel: string;
};

export function ImageCarousel({
  images,
  alt,
  label,
  noImage,
  previousLabel,
  nextLabel,
  imageLabel,
  openLabel,
  closeLabel,
}: ImageCarouselProps) {
  const trackRef = useRef<HTMLDivElement>(null);
  const [index, setIndex] = useState(0);
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);
  const go = (nextIndex: number) => {
    const track = trackRef.current;
    if (!track) return;
    const clamped = Math.max(0, Math.min(nextIndex, images.length - 1));
    track.scrollTo({ left: clamped * track.clientWidth, behavior: 'smooth' });
    setIndex(clamped);
  };
  // Follow the settled slide, not every intermediate frame: smooth-scroll
  // events would otherwise bounce the counter back (2/2 → 1/2 → 2/2).
  const settleTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const onScroll = () => {
    const track = trackRef.current;
    if (!track) return;
    clearTimeout(settleTimer.current);
    settleTimer.current = setTimeout(() => {
      const next = Math.round(track.scrollLeft / Math.max(1, track.clientWidth));
      setIndex(Math.max(0, Math.min(next, images.length - 1)));
    }, 100);
  };
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    go(index + (event.key === 'ArrowRight' ? 1 : -1));
  };
  return (
    <section aria-label={label} className="self-start">
      <div className="relative">
        <div
          ref={trackRef}
          className="flex aspect-square snap-x snap-mandatory overflow-x-auto border-[1.5px] border-edge bg-surface-high scrollbar-none [&::-webkit-scrollbar]:hidden"
          role="group"
          aria-roledescription="carousel"
          aria-label={label}
          tabIndex={images.length > 1 ? 0 : undefined}
          onKeyDown={onKeyDown}
          onScroll={onScroll}
        >
          {images.length ? (
            images.map((image, imageIndex) => (
              <div
                key={image.id ?? image.url}
                className="aspect-square flex-[0_0_100%] snap-start overflow-hidden"
                aria-hidden={imageIndex !== index}
              >
                <button
                  type="button"
                  className="block size-full cursor-zoom-in border-0 bg-transparent p-0 [&_img]:block [&_img]:size-full [&_img]:object-cover"
                  aria-label={openLabel(imageIndex)}
                  onClick={() => setViewerIndex(imageIndex)}
                >
                  <img
                    src={image.url}
                    alt={alt(imageIndex)}
                    fetchPriority={imageIndex === 0 ? 'high' : 'auto'}
                  />
                </button>
              </div>
            ))
          ) : (
            <div className="aspect-square flex-[0_0_100%] snap-start overflow-hidden grid place-items-center">
              {noImage}
            </div>
          )}
        </div>
        {images.length > 1 ? (
          <>
            <button
              type="button"
              className="absolute top-1/2 z-2 grid size-10 -translate-y-1/2 place-items-center border border-white/25 bg-black/80 text-white left-2.5 disabled:cursor-default disabled:opacity-35"
              aria-label={previousLabel}
              onClick={() => go(index - 1)}
              disabled={index === 0}
            >
              <Icon name="back" size={18} />
            </button>
            <button
              type="button"
              className="absolute top-1/2 z-2 grid size-10 -translate-y-1/2 place-items-center border border-white/25 bg-black/80 text-white right-2.5 disabled:cursor-default disabled:opacity-35"
              aria-label={nextLabel}
              onClick={() => go(index + 1)}
              disabled={index === images.length - 1}
            >
              <Icon name="chevronRight" size={18} />
            </button>
            <span className="absolute bottom-2.5 right-2.5 bg-black/80 px-2.5 py-1 font-display text-xs font-semibold text-white">
              {index + 1} / {images.length}
            </span>
            <div className="absolute bottom-2.5 left-1/2 flex -translate-x-1/2 gap-1.5 [&_button]:size-2 [&_button]:cursor-pointer [&_button]:rounded-full [&_button]:border-0 [&_button]:bg-white/50 [&_button[aria-current=true]]:bg-white">
              {images.map((image, imageIndex) => (
                <button
                  key={image.id ?? image.url}
                  type="button"
                  aria-label={imageLabel(imageIndex)}
                  aria-current={imageIndex === index ? 'true' : undefined}
                  onClick={() => go(imageIndex)}
                />
              ))}
            </div>
          </>
        ) : null}
      </div>
      {viewerIndex !== null ? (
        <ImageViewer
          items={images.map((image, imageIndex) => ({ src: image.url, alt: alt(imageIndex) }))}
          index={viewerIndex}
          onIndexChange={setViewerIndex}
          onClose={() => setViewerIndex(null)}
          closeLabel={closeLabel}
          previousLabel={previousLabel}
          nextLabel={nextLabel}
        />
      ) : null}
    </section>
  );
}
