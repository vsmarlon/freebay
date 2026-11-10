import { filters } from './constants';
import { rotatedImageSize } from './geometry';
import type { Point, Stroke } from './use-editor';

export type CanvasPaint = {
  canvas: HTMLCanvasElement;
  strokesCanvas: HTMLCanvasElement;
  image: CanvasImageSource;
  size: { width: number; height: number };
  angle: number;
  filter: number;
  brightness: number;
  contrast: number;
  saturation: number;
  strokes: readonly Stroke[];
  overlay: string;
  selection: { start: Point; end: Point } | null;
  showCrop: boolean;
};

/** Paints the edited image onto the canvas. Returns null when 2d is unavailable. */
export function paintEditor({
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
  showCrop,
}: CanvasPaint): HTMLCanvasElement | null {
  const { width: outputWidth, height: outputHeight } = rotatedImageSize(
    size.width,
    size.height,
    angle,
  );
  canvas.width = outputWidth;
  canvas.height = outputHeight;
  const context = canvas.getContext('2d');
  if (!context) return null;
  context.clearRect(0, 0, outputWidth, outputHeight);
  const radians = (angle * Math.PI) / 180;
  const rotationScale = Math.min(
    outputWidth /
      (Math.abs(size.width * Math.cos(radians)) + Math.abs(size.height * Math.sin(radians))),
    outputHeight /
      (Math.abs(size.height * Math.cos(radians)) + Math.abs(size.width * Math.sin(radians))),
  );
  context.save();
  context.translate(outputWidth / 2, outputHeight / 2);
  context.rotate(radians);
  context.scale(rotationScale, rotationScale);
  context.filter = `${filters[filter]} brightness(${brightness}) contrast(${contrast}) saturate(${saturation})`;
  context.drawImage(image, -size.width / 2, -size.height / 2, size.width, size.height);
  context.restore();
  context.filter = 'none';
  if (strokesCanvas.width !== outputWidth || strokesCanvas.height !== outputHeight) {
    strokesCanvas.width = outputWidth;
    strokesCanvas.height = outputHeight;
  }
  const strokesContext = strokesCanvas.getContext('2d');
  if (strokesContext)
    for (const stroke of strokes) {
      strokesContext.save();
      strokesContext.globalCompositeOperation =
        stroke.style === 'eraser' ? 'destination-out' : 'source-over';
      strokesContext.globalAlpha = stroke.style === 'highlighter' ? 0.31 : 1;
      strokesContext.beginPath();
      strokesContext.strokeStyle = stroke.color;
      strokesContext.lineWidth = (stroke.width * size.width) / 400;
      strokesContext.lineCap = stroke.style === 'marker' ? 'round' : 'square';
      stroke.points.forEach((point, index) =>
        index ? strokesContext.lineTo(point.x, point.y) : strokesContext.moveTo(point.x, point.y),
      );
      strokesContext.stroke();
      strokesContext.restore();
    }
  if (strokesContext) context.drawImage(strokesCanvas, 0, 0);
  if (overlay) {
    context.font = `bold ${Math.max(18, size.width / 18)}px sans-serif`;
    context.fillStyle = '#ffffff';
    context.strokeStyle = '#11100e';
    context.lineWidth = 3;
    context.strokeText(overlay, size.width * 0.08, size.height * 0.14);
    context.fillText(overlay, size.width * 0.08, size.height * 0.14);
  }
  if (selection && showCrop) {
    const x = Math.min(selection.start.x, selection.end.x);
    const y = Math.min(selection.start.y, selection.end.y);
    const width = Math.abs(selection.end.x - selection.start.x);
    const height = Math.abs(selection.end.y - selection.start.y);
    context.fillStyle = '#0006';
    context.fillRect(0, 0, size.width, size.height);
    context.clearRect(x, y, width, height);
    context.strokeStyle = '#fff';
    context.strokeRect(x, y, width, height);
  }
  return strokesCanvas;
}
