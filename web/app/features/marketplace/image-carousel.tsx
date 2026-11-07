import { useCallback, useRef, useState, type KeyboardEvent } from 'react';
import { Icon } from '../../components';

type CarouselImage = { id?: string; url: string };

type ImageCarouselProps = {
  images: CarouselImage[];
  alt: (index: number) => string;
  label: string;
  noImage: string;
  previousLabel: string;
  nextLabel: string;
  imageLabel: (index: number) => string;
};

export function ImageCarousel({ images, alt, label, noImage, previousLabel, nextLabel, imageLabel }: ImageCarouselProps) {
  const trackRef = useRef<HTMLDivElement>(null);
  const [index, setIndex] = useState(0);
  const go = useCallback((nextIndex: number) => {
    const track = trackRef.current;
    if (!track) return;
    const clamped = Math.max(0, Math.min(nextIndex, images.length - 1));
    track.scrollTo({ left: clamped * track.clientWidth, behavior: 'smooth' });
    setIndex(clamped);
  }, [images.length]);
  const onScroll = () => {
    const track = trackRef.current;
    if (!track) return;
    const next = Math.round(track.scrollLeft / Math.max(1, track.clientWidth));
    setIndex(Math.max(0, Math.min(next, images.length - 1)));
  };
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    go(index + (event.key === 'ArrowRight' ? 1 : -1));
  };
  return <section aria-label={label} className="market-gallery">
    <div className="market-gallery-stage">
      <div ref={trackRef} className="market-gallery-carousel" role="group" aria-roledescription="carousel" aria-label={label} tabIndex={images.length > 1 ? 0 : undefined} onKeyDown={onKeyDown} onScroll={onScroll}>
        {images.length ? images.map((image, imageIndex) => (
          <div key={image.id ?? image.url} className="market-gallery-slide" aria-hidden={imageIndex !== index}>
            <img src={image.url} alt={alt(imageIndex)} fetchPriority={imageIndex === 0 ? 'high' : 'auto'} />
          </div>
        )) : <div className="market-gallery-slide market-gallery-empty">{noImage}</div>}
      </div>
      {images.length > 1 ? <>
        <button type="button" className="market-gallery-arrow market-gallery-previous" aria-label={previousLabel} onClick={() => go(index - 1)} disabled={index === 0}><Icon name="back" size={18} /></button>
        <button type="button" className="market-gallery-arrow market-gallery-next" aria-label={nextLabel} onClick={() => go(index + 1)} disabled={index === images.length - 1}><Icon name="chevronRight" size={18} /></button>
        <span className="market-gallery-counter">{index + 1} / {images.length}</span>
        <div className="market-gallery-dots">{images.map((image, imageIndex) => <button key={image.id ?? image.url} type="button" aria-label={imageLabel(imageIndex)} aria-current={imageIndex === index ? 'true' : undefined} onClick={() => go(imageIndex)} />)}</div>
      </> : null}
    </div>
  </section>;
}
