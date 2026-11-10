import { boundedImageSize, supportedEditorFile } from './geometry';

export type LoadedSource =
  | { source: CanvasImageSource; width: number; height: number }
  | { error: true };

export function loadImageResource(file: File): Promise<LoadedSource> {
  return new Promise((resolve) => {
    if (!supportedEditorFile(file)) {
      resolve({ error: true });
      return;
    }
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = async () => {
      try {
        const dimensions = boundedImageSize(image.naturalWidth, image.naturalHeight);
        if (typeof createImageBitmap === 'function') {
          const bitmap = await createImageBitmap(image, {
            resizeWidth: dimensions.width,
            resizeHeight: dimensions.height,
            resizeQuality: 'high',
          });
          URL.revokeObjectURL(url);
          resolve({ source: bitmap, width: dimensions.width, height: dimensions.height });
        } else {
          URL.revokeObjectURL(url);
          resolve({ source: image, width: dimensions.width, height: dimensions.height });
        }
      } catch {
        URL.revokeObjectURL(url);
        resolve({ error: true });
      }
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      resolve({ error: true });
    };
    image.src = url;
  });
}
