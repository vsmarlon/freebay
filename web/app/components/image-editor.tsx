import { useCallback, useRef, useState } from 'react';
import { useLocation } from 'react-router';

const maxFileBytes = 32 * 1024 * 1024;
const maxDimension = 2048;
const filters = ['none', 'contrast(1.2) saturate(1.1)', 'brightness(.95) sepia(.08)', 'grayscale(1) contrast(1.2)', 'brightness(1.05) saturate(.95)', 'sepia(.2) contrast(.9)', 'saturate(1.2) hue-rotate(-8deg)'];
const names = { en: ['Crop', 'Rotate left', 'Rotate right', 'Filter', 'Text', 'Draw', 'Save image', 'Cancel', 'Add text', 'Image could not be edited.', 'Select a crop by dragging on the image.'], 'pt-BR': ['Cortar', 'Girar à esquerda', 'Girar à direita', 'Filtro', 'Texto', 'Desenhar', 'Salvar imagem', 'Cancelar', 'Adicionar texto', 'Não foi possível editar a imagem.', 'Selecione a área de corte arrastando sobre a imagem.'] } as const;

export function boundedImageSize(width: number, height: number, limit = maxDimension) {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width < 1 || height < 1 || width * height > 50_000_000) throw new RangeError('Unsupported image dimensions');
  const scale = Math.min(1, limit / Math.max(width, height));
  return { width: Math.max(1, Math.round(width * scale)), height: Math.max(1, Math.round(height * scale)) };
}
export function rotatedImageSize(width: number, height: number, angle: number) {
  const radians = angle * Math.PI / 180;
  const rotatedWidth = Math.abs(width * Math.cos(radians)) + Math.abs(height * Math.sin(radians));
  const rotatedHeight = Math.abs(height * Math.cos(radians)) + Math.abs(width * Math.sin(radians));
  const scale = Math.min(1, maxDimension / Math.max(rotatedWidth, rotatedHeight));
  return { width: Math.max(1, Math.ceil(rotatedWidth * scale - 1e-9)), height: Math.max(1, Math.ceil(rotatedHeight * scale - 1e-9)) };
}
export function supportedEditorFile(file: Pick<File, 'type' | 'size'>) {
  return file.type.startsWith('image/') && file.type !== 'image/svg+xml' && file.size > 0 && file.size <= maxFileBytes;
}
export function editedImageFile(blob: Blob | null, sourceName: string, lastModified = Date.now()) {
  if (!blob || !blob.size) throw new TypeError('Canvas export did not produce image data');
  return new File([blob], `${sourceName.replace(/\.[^.]+$/, '')}-edited.png`, { type: 'image/png', lastModified });
}

type ImageEditorProps = { file: File; onSave: (file: File) => void; onCancel: () => void };
type Point = { x: number; y: number };
type Stroke = { points: Point[]; color: string; width: number; style: 'marker' | 'highlighter' | 'eraser' };

type LoadedSource = { source: CanvasImageSource; width: number; height: number } | { error: true };

function loadImageResource(file: File): Promise<LoadedSource> {
  return new Promise((resolve) => {
    if (!supportedEditorFile(file)) { resolve({ error: true }); return; }
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = async () => {
      try {
        const dimensions = boundedImageSize(image.naturalWidth, image.naturalHeight);
        if (typeof createImageBitmap === 'function') {
          const bitmap = await createImageBitmap(image, { resizeWidth: dimensions.width, resizeHeight: dimensions.height, resizeQuality: 'high' });
          URL.revokeObjectURL(url);
          resolve({ source: bitmap, width: dimensions.width, height: dimensions.height });
        } else {
          URL.revokeObjectURL(url);
          resolve({ source: image, width: dimensions.width, height: dimensions.height });
        }
      } catch { URL.revokeObjectURL(url); resolve({ error: true }); }
    };
    image.onerror = () => { URL.revokeObjectURL(url); resolve({ error: true }); };
    image.src = url;
  });
}

export function ImageEditor({ file, onSave, onCancel }: ImageEditorProps) {
  const location = useLocation();
  const locale = location.pathname.split('/')[1] === 'en' ? 'en' : 'pt-BR';
  const label = names[locale];
  // The decoded image arrives asynchronously: load it through a callback ref
  // and hold the result in state. `use()` with a promise created during
  // render (useMemo) suspends the shell in a loop until React gives up with
  // "async Client Component" — seen live as a full Application Error when
  // attaching any photo on web.
  const [loaded, setLoaded] = useState<LoadedSource | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const strokesCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const imageRef = useRef<CanvasImageSource | null>(null);
  if (loaded && !('error' in loaded)) imageRef.current = loaded.source;
  const startRef = useRef<Point | null>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const [size, setSize] = useState({ width: loaded && !('error' in loaded) ? loaded.width : 0, height: loaded && !('error' in loaded) ? loaded.height : 0 });
  const [error, setError] = useState('');
  const [angle, setAngle] = useState(0);
  const [filter, setFilter] = useState(0);
  const [brightness, setBrightness] = useState(1);
  const [contrast, setContrast] = useState(1);
  const [saturation, setSaturation] = useState(1);
  const [drawColor, setDrawColor] = useState('#8a1083');
  const [drawWidth, setDrawWidth] = useState(8);
  const [penStyle, setPenStyle] = useState<Stroke['style']>('marker');
  const [tool, setTool] = useState<'crop' | 'draw'>('crop');
  const [selection, setSelection] = useState<{ start: Point; end: Point } | null>(null);
  const [text, setText] = useState('');
  const [overlay, setOverlay] = useState('');
  const [drawingVersion, setDrawingVersion] = useState(0);
  const sourceRef = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    let alive = true;
    void loadImageResource(file).then((result) => {
      if (!alive) return;
      setLoaded(result);
      if (!('error' in result)) setSize({ width: result.width, height: result.height });
    });
    return () => { alive = false; };
  }, [file]);

  const redraw = useCallback((canvas: HTMLCanvasElement | null) => {
    canvasRef.current = canvas;
    const image = imageRef.current;
    if (!canvas || !image) return;
    const outputSize = rotatedImageSize(size.width, size.height, angle);
    canvas.width = outputSize.width; canvas.height = outputSize.height;
    const context = canvas.getContext('2d');
    if (!context) { setError(label[9]); return; }
    context.clearRect(0, 0, outputSize.width, outputSize.height);
    const rotationScale = Math.min(outputSize.width / (Math.abs(size.width * Math.cos(angle * Math.PI / 180)) + Math.abs(size.height * Math.sin(angle * Math.PI / 180))), outputSize.height / (Math.abs(size.height * Math.cos(angle * Math.PI / 180)) + Math.abs(size.width * Math.sin(angle * Math.PI / 180))));
    context.save(); context.translate(outputSize.width / 2, outputSize.height / 2);
    context.rotate(angle * Math.PI / 180); context.scale(rotationScale, rotationScale);
    context.filter = `${filters[filter]} brightness(${brightness}) contrast(${contrast}) saturate(${saturation})`;
    context.drawImage(image, -size.width / 2, -size.height / 2, size.width, size.height);
    context.restore(); context.filter = 'none';
    const strokesCanvas = strokesCanvasRef.current ?? document.createElement('canvas');
    strokesCanvasRef.current = strokesCanvas;
    if (strokesCanvas.width !== outputSize.width || strokesCanvas.height !== outputSize.height) { strokesCanvas.width = outputSize.width; strokesCanvas.height = outputSize.height; }
    const strokesContext = strokesCanvas.getContext('2d');
    if (strokesContext) for (const stroke of strokesRef.current) { strokesContext.save(); strokesContext.globalCompositeOperation = stroke.style === 'eraser' ? 'destination-out' : 'source-over'; strokesContext.globalAlpha = stroke.style === 'highlighter' ? .31 : 1; strokesContext.beginPath(); strokesContext.strokeStyle = stroke.color; strokesContext.lineWidth = stroke.width * size.width / 400; strokesContext.lineCap = stroke.style === 'marker' ? 'round' : 'square'; stroke.points.forEach((point, index) => index ? strokesContext.lineTo(point.x, point.y) : strokesContext.moveTo(point.x, point.y)); strokesContext.stroke(); strokesContext.restore(); }
    if (strokesContext) context.drawImage(strokesCanvas, 0, 0);
    if (overlay) { context.font = `bold ${Math.max(18, size.width / 18)}px sans-serif`; context.fillStyle = '#ffffff'; context.strokeStyle = '#11100e'; context.lineWidth = 3; context.strokeText(overlay, size.width * .08, size.height * .14); context.fillText(overlay, size.width * .08, size.height * .14); }
    if (selection && tool === 'crop') { context.fillStyle = '#0006'; context.fillRect(0, 0, size.width, size.height); context.clearRect(Math.min(selection.start.x, selection.end.x), Math.min(selection.start.y, selection.end.y), Math.abs(selection.end.x - selection.start.x), Math.abs(selection.end.y - selection.start.y)); context.strokeStyle = '#fff'; context.strokeRect(Math.min(selection.start.x, selection.end.x), Math.min(selection.start.y, selection.end.y), Math.abs(selection.end.x - selection.start.x), Math.abs(selection.end.y - selection.start.y)); }
  }, [angle, brightness, contrast, drawingVersion, drawColor, drawWidth, filter, overlay, saturation, selection, size, tool, label]);

  const point = (event: React.PointerEvent<HTMLCanvasElement>): Point => { const rect = event.currentTarget.getBoundingClientRect(); return { x: (event.clientX - rect.left) * event.currentTarget.width / rect.width, y: (event.clientY - rect.top) * event.currentTarget.height / rect.height }; };
  const pointerDown = (event: React.PointerEvent<HTMLCanvasElement>) => { event.currentTarget.setPointerCapture(event.pointerId); const p = point(event); startRef.current = p; if (tool === 'draw') strokesRef.current = [...strokesRef.current, { points: [p], color: drawColor, width: drawWidth, style: penStyle }]; else setSelection({ start: p, end: p }); };
  const pointerMove = (event: React.PointerEvent<HTMLCanvasElement>) => { if (!startRef.current) return; const p = point(event); if (tool === 'draw') { const strokes = strokesRef.current; strokes[strokes.length - 1].points.push(p); setDrawingVersion((version) => version + 1); } else setSelection((selection) => selection ? { ...selection, end: p } : null); };
  const pointerUp = () => { startRef.current = null; };
  const applyCrop = () => { if (!selection) return; const x = Math.min(selection.start.x, selection.end.x), y = Math.min(selection.start.y, selection.end.y); const width = Math.abs(selection.end.x - selection.start.x), height = Math.abs(selection.end.y - selection.start.y); if (width < 2 || height < 2) return; const canvas = canvasRef.current; if (!canvas) return; const crop = document.createElement('canvas'); crop.width = Math.round(width); crop.height = Math.round(height); crop.getContext('2d')?.drawImage(canvas, x, y, width, height, 0, 0, crop.width, crop.height); const cropped = new Image(); cropped.onload = () => setSize({ width: crop.width, height: crop.height }); cropped.src = crop.toDataURL('image/png'); if (imageRef.current instanceof ImageBitmap) imageRef.current.close(); imageRef.current = cropped; setSelection(null); setAngle(0); setFilter(0); strokesRef.current = []; setOverlay(''); };
  const moveCropWithKeyboard = (event: React.KeyboardEvent<HTMLCanvasElement>) => {
    if (tool !== 'crop' || !['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key)) return;
    event.preventDefault();
    const dx = event.key === 'ArrowLeft' ? -10 : event.key === 'ArrowRight' ? 10 : 0;
    const dy = event.key === 'ArrowUp' ? -10 : event.key === 'ArrowDown' ? 10 : 0;
    const width = canvasRef.current?.width ?? size.width, height = canvasRef.current?.height ?? size.height;
    setSelection((current) => current ? { start: { x: current.start.x + dx, y: current.start.y + dy }, end: { x: current.end.x + dx, y: current.end.y + dy } } : { start: { x: width * .1, y: height * .1 }, end: { x: width * .9, y: height * .9 } });
  };
  const save = async () => { const canvas = canvasRef.current; if (!canvas) return; try { const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/png')); onSave(editedImageFile(blob, file.name)); } catch { setError(label[9]); } };

  return <section className="grid max-w-full gap-3 p-4" aria-label={locale === 'en' ? 'Image editor' : 'Editor de imagem'}>
    <div ref={sourceRef} hidden />
    {loaded === null ? null : 'error' in loaded ? <p role="alert">{label[9]}</p> : <>
    <div className="flex flex-wrap gap-2 [&>label]:flex [&>label]:items-center [&>label]:gap-1.5 [&_select]:min-h-10 [&_select]:border [&_select]:border-ink [&_select]:bg-surface [&_select]:p-1.5 [&_select]:text-ink">
      <button type="button" onClick={applyCrop} disabled={!selection}>{label[0]}</button>
      <button type="button" onClick={() => setAngle((value) => value - 90)}>{label[1]}</button><button type="button" onClick={() => setAngle((value) => value + 90)}>{label[2]}</button>
      <label>{label[3]} <select aria-label={label[3]} value={filter} onChange={(event) => setFilter(Number(event.currentTarget.value))}>{filters.map((_, index) => <option key={index} value={index}>{(locale === 'en' ? ['Normal', 'Clarendon', 'Gingham', 'Moon', 'Lark', 'Reyes', 'Juno'] : ['Normal', 'Clarendon', 'Gingham', 'Lua', 'Lark', 'Reyes', 'Juno'])[index]}</option>)}</select></label>
      <label>{locale === 'en' ? 'Brightness' : 'Brilho'}<input aria-label={locale === 'en' ? 'Brightness' : 'Brilho'} type="range" min="0" max="2" step=".05" value={brightness} onChange={(event) => setBrightness(Number(event.currentTarget.value))} /></label>
      <label>{locale === 'en' ? 'Contrast' : 'Contraste'}<input aria-label={locale === 'en' ? 'Contrast' : 'Contraste'} type="range" min="0" max="2" step=".05" value={contrast} onChange={(event) => setContrast(Number(event.currentTarget.value))} /></label>
      <label>{locale === 'en' ? 'Saturation' : 'Saturação'}<input aria-label={locale === 'en' ? 'Saturation' : 'Saturação'} type="range" min="0" max="2" step=".05" value={saturation} onChange={(event) => setSaturation(Number(event.currentTarget.value))} /></label>
      <label>{locale === 'en' ? 'Rotation' : 'Rotação'}<input aria-label={locale === 'en' ? 'Rotation' : 'Rotação'} type="range" min="-180" max="180" step="1" value={((angle + 180) % 360 + 360) % 360 - 180} onChange={(event) => setAngle(Number(event.currentTarget.value))} /></label>
      <button type="button" onClick={() => { const value = window.prompt(label[8], text || (locale === 'en' ? 'NEW TEXT' : 'NOVO TEXTO')); if (value !== null) { setText(value.slice(0, 2000)); setOverlay(value.slice(0, 2000)); } }}>{label[4]}</button>
      <button type="button" aria-pressed={tool === 'draw'} onClick={() => setTool(tool === 'draw' ? 'crop' : 'draw')}>{label[5]}</button>
      {tool === 'draw' && <><label>{locale === 'en' ? 'Draw color' : 'Cor do traço'}<input aria-label={locale === 'en' ? 'Draw color' : 'Cor do traço'} type="color" value={drawColor} onChange={(event) => setDrawColor(event.currentTarget.value)} /></label><label>{locale === 'en' ? 'Pen style' : 'Estilo do traço'}<select aria-label={locale === 'en' ? 'Pen style' : 'Estilo do traço'} value={penStyle} onChange={(event) => setPenStyle(event.currentTarget.value as Stroke['style'])}><option value="marker">{locale === 'en' ? 'Marker' : 'Marcador'}</option><option value="highlighter">{locale === 'en' ? 'Highlighter' : 'Marca-texto'}</option><option value="eraser">{locale === 'en' ? 'Eraser' : 'Borracha'}</option></select></label><label>{locale === 'en' ? 'Draw width' : 'Espessura'}<input aria-label={locale === 'en' ? 'Draw width' : 'Espessura'} type="range" min="2" max="24" value={drawWidth} onChange={(event) => setDrawWidth(Number(event.currentTarget.value))} /></label><button type="button" disabled={!strokesRef.current.length} onClick={() => { strokesRef.current.pop(); setDrawingVersion((version) => version + 1); }}>{locale === 'en' ? 'Undo' : 'Desfazer'}</button><button type="button" disabled={!strokesRef.current.length} onClick={() => { strokesRef.current = []; setDrawingVersion((version) => version + 1); }}>{locale === 'en' ? 'Clear' : 'Limpar'}</button></>}
    </div>
    <p id="image-editor-hint" className="text-muted">{label[10]}</p>
    <canvas className="m-auto block max-h-[60svh] max-w-full touch-none object-contain" ref={redraw} tabIndex={0} aria-label={label[0]} aria-describedby="image-editor-hint" onKeyDown={moveCropWithKeyboard} onPointerDown={pointerDown} onPointerMove={pointerMove} onPointerUp={pointerUp} onPointerCancel={pointerUp} />
    {error && <p role="alert">{error}</p>}
    <footer className="flex justify-end gap-2.5"><button type="button" className="min-h-10 border border-ink bg-surface px-3 text-ink" onClick={onCancel}>{label[7]}</button><button type="button" className="min-h-10 border border-ink bg-brand px-3.5 font-display text-[13px] font-bold text-white disabled:cursor-not-allowed disabled:opacity-50" onClick={() => void save()} disabled={Boolean(error) || !imageRef.current}>{label[6]}</button></footer>
    </>}
  </section>;
}
