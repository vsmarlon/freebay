export const ALLOWED_IMAGE_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
] as const;

export const MAX_IMAGE_SIZE = 5 * 1024 * 1024;

export function validateImageFile(file: Express.Multer.File): string | null {
  if (!ALLOWED_IMAGE_MIMES.includes(file.mimetype as typeof ALLOWED_IMAGE_MIMES[number])) {
    return `Formato de imagem não suportado: ${file.mimetype}. Use JPEG, PNG, WebP ou GIF.`;
  }
  if (file.size > MAX_IMAGE_SIZE) {
    return `Imagem muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 5MB.`;
  }
  return null;
}
