import { useCallback } from 'react';
import { Icon } from './index';

export type ImageViewerItem = { src: string; alt: string };

export function ImageViewer({ items, index, onIndexChange, onClose, closeLabel, previousLabel, nextLabel }: {
  items: ImageViewerItem[];
  index: number;
  onIndexChange: (index: number) => void;
  onClose: () => void;
  closeLabel: string;
  previousLabel: string;
  nextLabel: string;
}) {
  const show = useCallback((node: HTMLDialogElement | null) => {
    if (node && !node.open) node.showModal();
  }, []);
  const item = items[index];
  if (!item) return null;
  const move = (offset: number) => onIndexChange((index + offset + items.length) % items.length);
  return (
    <dialog
      ref={show}
      className="fixed inset-0 m-0 grid h-svh max-h-none w-screen max-w-none place-items-center border-0 bg-transparent p-0 text-white backdrop:bg-black/90 open:grid"
      onClose={onClose}
      onClick={(event) => { if (event.target === event.currentTarget) onClose(); }}
      onKeyDown={(event) => {
        if (items.length < 2) return;
        if (event.key === 'ArrowLeft') { event.preventDefault(); move(-1); }
        if (event.key === 'ArrowRight') { event.preventDefault(); move(1); }
      }}
    >
      <button type="button" className="absolute top-4 right-4 z-1 grid size-11 cursor-pointer place-items-center border border-white/20 bg-[#1c1c1cd9] text-white" onClick={onClose} aria-label={closeLabel}><Icon name="close" size={20} /></button>
      {items.length > 1 ? <button type="button" className="absolute top-1/2 left-4 z-1 grid size-11 -translate-y-1/2 cursor-pointer place-items-center border border-white/20 bg-[#1c1c1cd9] text-white" onClick={() => move(-1)} aria-label={previousLabel}><Icon name="back" size={20} /></button> : null}
      <img className="max-h-[92svh] max-w-[94vw] object-contain" src={item.src} alt={item.alt} />
      {items.length > 1 ? <button type="button" className="absolute top-1/2 right-4 z-1 grid size-11 -translate-y-1/2 cursor-pointer place-items-center border border-white/20 bg-[#1c1c1cd9] text-white" onClick={() => move(1)} aria-label={nextLabel}><Icon name="chevronRight" size={20} /></button> : null}
      {items.length > 1 ? <span className="absolute bottom-4 left-1/2 -translate-x-1/2 font-display text-xs font-bold text-white">{index + 1} / {items.length}</span> : null}
    </dialog>
  );
}
