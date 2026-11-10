const maxFileBytes = 32 * 1024 * 1024;
const maxDimension = 2048;

export function boundedImageSize(width: number, height: number, limit = maxDimension) {
  if (
    !Number.isFinite(width) ||
    !Number.isFinite(height) ||
    width < 1 ||
    height < 1 ||
    width * height > 50_000_000
  )
    throw new RangeError('Unsupported image dimensions');
  const scale = Math.min(1, limit / Math.max(width, height));
  return {
    width: Math.max(1, Math.round(width * scale)),
    height: Math.max(1, Math.round(height * scale)),
  };
}
export function rotatedImageSize(width: number, height: number, angle: number) {
  const radians = (angle * Math.PI) / 180;
  const rotatedWidth = Math.abs(width * Math.cos(radians)) + Math.abs(height * Math.sin(radians));
  const rotatedHeight = Math.abs(height * Math.cos(radians)) + Math.abs(width * Math.sin(radians));
  const scale = Math.min(1, maxDimension / Math.max(rotatedWidth, rotatedHeight));
  return {
    width: Math.max(1, Math.ceil(rotatedWidth * scale - 1e-9)),
    height: Math.max(1, Math.ceil(rotatedHeight * scale - 1e-9)),
  };
}
export function supportedEditorFile(file: Pick<File, 'type' | 'size'>) {
  return (
    file.type.startsWith('image/') &&
    file.type !== 'image/svg+xml' &&
    file.size > 0 &&
    file.size <= maxFileBytes
  );
}
export function editedImageFile(blob: Blob | null, sourceName: string, lastModified = Date.now()) {
  if (!blob || !blob.size) throw new TypeError('Canvas export did not produce image data');
  return new File([blob], `${sourceName.replace(/\.[^.]+$/, '')}-edited.png`, {
    type: 'image/png',
    lastModified,
  });
}
