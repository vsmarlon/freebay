export const ALLOWED_IMAGE_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
] as const;

export const MAX_IMAGE_SIZE = 5 * 1024 * 1024;

export function validateImageFile(
  file: Express.Multer.File,
  maxSizeBytes: number = MAX_IMAGE_SIZE,
): string | null {
  if (!ALLOWED_IMAGE_MIMES.includes(file.mimetype as typeof ALLOWED_IMAGE_MIMES[number])) {
    return `Formato de imagem não suportado: ${file.mimetype}. Use JPEG, PNG, WebP ou GIF.`;
  }
  if (file.size > maxSizeBytes) {
    return `Imagem muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: ${(maxSizeBytes / 1024 / 1024).toFixed(0)}MB.`;
  }
  return null;
}
