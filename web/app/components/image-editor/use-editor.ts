import { useCallback, useRef, useState } from 'react';
import { editedImageFile } from './geometry';
import { paintEditor } from './render-canvas';

export type Point = { x: number; y: number };
export type Stroke = {
  points: Point[];
  color: string;
  width: number;
  style: 'marker' | 'highlighter' | 'eraser';
};

export function useEditor({
  file,
  image,
  setImage,
  size,
  setSize,
  label,
  onSave,
}: {
  file: File;
  image: CanvasImageSource | null;
  setImage: (image: CanvasImageSource) => void;
  size: { width: number; height: number };
  setSize: (size: { width: number; height: number }) => void;
  label: readonly string[];
  onSave: (file: File) => void;
}) {
  const [strokes, setStrokes] = useState<Stroke[]>([]);
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
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const strokesCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const startRef = useRef<Point | null>(null);

  const redraw = useCallback(
    (canvas: HTMLCanvasElement | null) => {
      canvasRef.current = canvas;
      if (!canvas || !image) return;
      const strokesCanvas = strokesCanvasRef.current ?? document.createElement('canvas');
      strokesCanvasRef.current = strokesCanvas;
      const painted = paintEditor({
        canvas,
        strokesCanvas,
        image,
        size,
        angle,
        filter,
        brightness,
        contrast,
        saturation,
        strokes,
        overlay,
        selection,
        showCrop: tool === 'crop',
      });
      if (!painted) setError(label[9]);
    },
    [
      angle,
      brightness,
      contrast,
      filter,
      image,
      overlay,
      saturation,
      selection,
      size,
      strokes,
      tool,
      label,
    ],
  );

  const point = (event: React.PointerEvent<HTMLCanvasElement>): Point => {
    const rect = event.currentTarget.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) * event.currentTarget.width) / rect.width,
      y: ((event.clientY - rect.top) * event.currentTarget.height) / rect.height,
    };
  };
  const pointerDown = (event: React.PointerEvent<HTMLCanvasElement>) => {
    event.currentTarget.setPointerCapture(event.pointerId);
    const p = point(event);
    startRef.current = p;
    if (tool === 'draw')
      setStrokes((current) => [
        ...current,
        { points: [p], color: drawColor, width: drawWidth, style: penStyle },
      ]);
    else setSelection({ start: p, end: p });
  };
  const pointerMove = (event: React.PointerEvent<HTMLCanvasElement>) => {
    if (!startRef.current) return;
    const p = point(event);
    if (tool === 'draw')
      setStrokes((current) =>
        current.map((stroke, index) =>
          index === current.length - 1 ? { ...stroke, points: [...stroke.points, p] } : stroke,
        ),
      );
    else setSelection((selection) => (selection ? { ...selection, end: p } : null));
  };
  const pointerUp = () => {
    startRef.current = null;
  };
  const applyCrop = () => {
    if (!selection) return;
    const x = Math.min(selection.start.x, selection.end.x),
      y = Math.min(selection.start.y, selection.end.y);
    const width = Math.abs(selection.end.x - selection.start.x),
      height = Math.abs(selection.end.y - selection.start.y);
    if (width < 2 || height < 2) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const crop = document.createElement('canvas');
    crop.width = Math.round(width);
    crop.height = Math.round(height);
    crop.getContext('2d')?.drawImage(canvas, x, y, width, height, 0, 0, crop.width, crop.height);
    const cropped = new Image();
    cropped.onload = () => setSize({ width: crop.width, height: crop.height });
    cropped.src = crop.toDataURL('image/png');
    if (image instanceof ImageBitmap) image.close();
    setImage(cropped);
    setSelection(null);
    setAngle(0);
    setFilter(0);
    setStrokes([]);
    setOverlay('');
  };
  const moveCropWithKeyboard = (event: React.KeyboardEvent<HTMLCanvasElement>) => {
    if (tool !== 'crop' || !['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key))
      return;
    event.preventDefault();
    const dx = event.key === 'ArrowLeft' ? -10 : event.key === 'ArrowRight' ? 10 : 0;
    const dy = event.key === 'ArrowUp' ? -10 : event.key === 'ArrowDown' ? 10 : 0;
    const width = canvasRef.current?.width ?? size.width,
      height = canvasRef.current?.height ?? size.height;
    setSelection((current) =>
      current
        ? {
            start: { x: current.start.x + dx, y: current.start.y + dy },
            end: { x: current.end.x + dx, y: current.end.y + dy },
          }
        : { start: { x: width * 0.1, y: height * 0.1 }, end: { x: width * 0.9, y: height * 0.9 } },
    );
  };
  const save = async () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    try {
      const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/png'));
      onSave(editedImageFile(blob, file.name));
    } catch {
      setError(label[9]);
    }
  };

  return {
    strokes,
    setStrokes,
    error,
    angle,
    setAngle,
    filter,
    setFilter,
    brightness,
    setBrightness,
    contrast,
    setContrast,
    saturation,
    setSaturation,
    drawColor,
    setDrawColor,
    drawWidth,
    setDrawWidth,
    penStyle,
    setPenStyle,
    tool,
    setTool,
    selection,
    text,
    setText,
    overlay,
    setOverlay,
    redraw,
    pointerDown,
    pointerMove,
    pointerUp,
    moveCropWithKeyboard,
    applyCrop,
    save,
  };
}

export type EditorState = ReturnType<typeof useEditor>;
