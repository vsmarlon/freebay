import { useEffect, useState, type PointerEvent } from 'react';

export type StoryTextBlock = { id: string; text: string; x: number; y: number; scale: number; rotation: number; color: number; style: 'classic' | 'strong' | 'editorial' | 'compact'; zIndex: number };
const colors = [{ label: 'White', value: 0xffffffff }, { label: 'Black', value: 0xff000000 }, { label: 'Brand', value: 0xff8a1083 }, { label: 'Warning', value: 0xfff59e0b }];
const styles = ['classic', 'strong', 'editorial', 'compact'] as const;
const classByStyle = { classic: 'font-body font-medium', strong: 'font-display font-extrabold', editorial: 'font-display font-semibold tracking-wide', compact: 'font-body font-bold' };
const cssColor = (color: number) => { const argb = color >>> 0; return `rgba(${(argb >>> 16) & 255},${(argb >>> 8) & 255},${argb & 255},${((argb >>> 24) & 255) / 255})`; };

export function serializeStoryTextBlocks(blocks: StoryTextBlock[]): string {
  return JSON.stringify([...blocks].sort((a, b) => a.zIndex - b.zIndex).map((block) => ({ ...block, text: block.text.trim() })));
}

export function StoryTextOverlays({ blocks, className = '' }: { blocks: StoryTextBlock[]; className?: string }) {
  return <>{[...blocks].sort((a, b) => a.zIndex - b.zIndex).map((block) => <span key={block.id} className={`pointer-events-none absolute z-10 max-w-[90%] whitespace-pre-wrap text-center [text-shadow:0_1px_3px_#000] ${classByStyle[block.style]} ${className}`} style={{ left: `${block.x * 100}%`, top: `${block.y * 100}%`, transform: `translate(-50%,-50%) rotate(${block.rotation}rad)`, fontSize: `${(block.style === 'compact' ? 16 : 24) * block.scale}px`, color: cssColor(block.color) }}>{block.text}</span>)}</>;
}

export function StoryTextBlockEditor({ file, caption = '', blocks, onChange, copy }: { file: File; caption?: string; blocks: StoryTextBlock[]; onChange: (blocks: StoryTextBlock[]) => void; copy: { addText: string; removeText: string; text: string; style: string; color: string; positionX: string; positionY: string; size: string; rotation: string; layer: string; videoPreview: string; defaultText: string; colors: string[] } }) {
  const [url, setUrl] = useState('');
  const [selectedId, setSelectedId] = useState<string>();
  const selected = blocks.find((block) => block.id === selectedId);
  useEffect(() => { const next = URL.createObjectURL(file); setUrl(next); return () => URL.revokeObjectURL(next); }, [file]);
  const update = (patch: Partial<StoryTextBlock>) => { if (selected) onChange(blocks.map((block) => block.id === selected.id ? { ...block, ...patch } : block)); };
  const dragStart = (event: PointerEvent<HTMLSpanElement>) => { if (!selected) return; event.currentTarget.setPointerCapture(event.pointerId); };
  const drag = (event: PointerEvent<HTMLSpanElement>) => { if (!selected || !event.currentTarget.hasPointerCapture(event.pointerId)) return; const bounds = event.currentTarget.parentElement?.getBoundingClientRect(); if (!bounds) return; update({ x: Math.max(0, Math.min(1, (event.clientX - bounds.left) / bounds.width)), y: Math.max(0, Math.min(1, (event.clientY - bounds.top) / bounds.height)) }); };
  const add = () => { if (blocks.length >= 10) return; const block = { id: crypto.randomUUID(), text: copy.defaultText, x: .5, y: .5, scale: 1, rotation: 0, color: 0xffffffff, style: 'classic' as const, zIndex: Math.max(-1, ...blocks.map((item) => item.zIndex)) + 1 }; onChange([...blocks, block]); setSelectedId(block.id); };
  const remove = () => { if (!selected) return; onChange(blocks.filter((block) => block.id !== selected.id)); setSelectedId(undefined); };
  const moveForward = () => { if (!selected) return; const ordered = [...blocks].sort((a, b) => a.zIndex - b.zIndex); const index = ordered.findIndex((block) => block.id === selected.id); if (index < 0 || index === ordered.length - 1) return; [ordered[index], ordered[index + 1]] = [ordered[index + 1], ordered[index]]; onChange(ordered.map((block, zIndex) => ({ ...block, zIndex }))); };

  return <section className="grid gap-3" aria-label={copy.text}>
    <div className="relative aspect-[9/16] max-h-[65vh] overflow-hidden bg-black" aria-label={copy.videoPreview}>
      {file.type.startsWith('video/') ? <video className="h-full w-full object-cover" src={url} controls playsInline preload="metadata" /> : <img className="h-full w-full object-cover" src={url} alt="" />}
      <div className="absolute inset-0 touch-none">
        {blocks.map((block) => <span key={block.id} role="button" tabIndex={0} aria-label={block.text || copy.text} aria-pressed={selectedId === block.id} onClick={() => setSelectedId(block.id)} onPointerDown={dragStart} onPointerMove={selectedId === block.id ? drag : undefined} onKeyDown={(event) => { if (event.key === 'Enter' || event.key === ' ') setSelectedId(block.id); }} className={`absolute max-w-[90%] cursor-move select-none whitespace-pre-wrap text-center [text-shadow:0_1px_3px_#000] ${classByStyle[block.style]} ${selectedId === block.id ? 'outline outline-2 outline-brand' : ''}`} style={{ left: `${block.x * 100}%`, top: `${block.y * 100}%`, zIndex: block.zIndex + 1, transform: `translate(-50%,-50%) rotate(${block.rotation}rad)`, fontSize: `${(block.style === 'compact' ? 16 : 24) * block.scale}px`, color: cssColor(block.color) }}>{block.text || ' '}</span>)}
        {caption ? <p className="pointer-events-none absolute inset-x-4 bottom-5 z-20 text-center text-white [text-shadow:0_1px_3px_#000]">{caption}</p> : null}
      </div>
    </div>
    <div className="flex flex-wrap gap-2"><button type="button" className="ui-button ui-secondary ui-sm" disabled={blocks.length >= 10} onClick={add}>{copy.addText}</button><button type="button" className="ui-button ui-secondary ui-sm" disabled={!selected} onClick={remove}>{copy.removeText}</button><button type="button" className="ui-button ui-secondary ui-sm" disabled={!selected} onClick={moveForward}>{copy.layer}</button></div>
    {selected ? <div className="grid gap-3 bg-surface-mid p-3 sm:grid-cols-2">
      <label className="ui-field sm:col-span-2">{copy.text}<textarea maxLength={200} value={selected.text} onChange={(event) => update({ text: event.currentTarget.value })} /></label>
      <label className="ui-field">{copy.style}<select value={selected.style} onChange={(event) => update({ style: event.currentTarget.value as StoryTextBlock['style'] })}>{styles.map((style) => <option key={style} value={style}>{style}</option>)}</select></label>
      <label className="ui-field">{copy.color}<select value={selected.color} onChange={(event) => update({ color: Number(event.currentTarget.value) })}>{colors.map((color, index) => <option key={color.value} value={color.value}>{copy.colors[index]}</option>)}</select></label>
      {([['x', copy.positionX, 0, 1, .01], ['y', copy.positionY, 0, 1, .01], ['scale', copy.size, .5, 3, .05], ['rotation', copy.rotation, -Math.PI, Math.PI, .01]] as const).map(([key, label, min, max, step]) => <label key={key} className="ui-field">{label}<input type="range" min={min} max={max} step={step} value={selected[key]} onChange={(event) => update({ [key]: Number(event.currentTarget.value) })} /><input type="number" min={min} max={max} step={step} value={selected[key]} onChange={(event) => update({ [key]: Number(event.currentTarget.value) })} /></label>)}
    </div> : null}
  </section>;
}
