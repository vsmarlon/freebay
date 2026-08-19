export const ALLOWED_IMAGE_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
] as const;

export const ALLOWED_AUDIO_MIMES = [
  'audio/mpeg',
  'audio/mp3',
  'audio/mp4',
  'audio/m4a',
  'audio/x-m4a',
  'audio/aac',
  'audio/ogg',
  'audio/wav',
  'audio/webm',
] as const;

export const ALLOWED_VIDEO_MIMES = [
  'video/mp4',
  'video/webm',
] as const;

export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_AUDIO_SIZE = 10 * 1024 * 1024; // 10MB
export const MAX_VIDEO_SIZE = 25 * 1024 * 1024; // 25MB
export const MAX_MEDIA_SIZE = MAX_VIDEO_SIZE; // 25MB overall upload limit

export const MIMETYPE_EXTENSIONS: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/gif': '.gif',
  'image/webp': '.webp',
  'audio/mpeg': '.mp3',
  'audio/mp3': '.mp3',
  'audio/mp4': '.m4a',
  'audio/m4a': '.m4a',
  'audio/x-m4a': '.m4a',
  'audio/aac': '.aac',
  'audio/ogg': '.ogg',
  'audio/wav': '.wav',
  'audio/webm': '.weba',
  'video/mp4': '.mp4',
  'video/webm': '.webm',
};

export function validateMediaFile(file: Express.Multer.File): string | null {
  const mime = file.mimetype;
  if (ALLOWED_IMAGE_MIMES.includes(mime as any)) {
    if (file.size > MAX_IMAGE_SIZE) {
      return `Imagem muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 5MB.`;
    }
    return null;
  }

  if (ALLOWED_AUDIO_MIMES.includes(mime as any)) {
    if (file.size > MAX_AUDIO_SIZE) {
      return `Áudio muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 10MB.`;
    }
    return null;
  }

  if (ALLOWED_VIDEO_MIMES.includes(mime as any)) {
    if (file.size > MAX_VIDEO_SIZE) {
      return `Vídeo muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 25MB.`;
    }
    return null;
  }

  return `Tipo de arquivo não suportado: ${mime}. Aceitos: Imagens (JPEG, PNG, WebP, GIF), Áudio (MP3, M4A, AAC, OGG, WAV), Vídeo (MP4, WebM).`;
}

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
