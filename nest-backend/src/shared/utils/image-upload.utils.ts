export const ALLOWED_IMAGE_MIMES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
] as const;

export const ALLOWED_AUDIO_MIMES = [
  "audio/mpeg",
  "audio/mp3",
  "audio/mp4",
  "audio/m4a",
  "audio/x-m4a",
  "audio/aac",
  "audio/ogg",
  "audio/wav",
  "audio/webm",
] as const;

export const ALLOWED_VIDEO_MIMES = [
  "video/mp4",
  "video/quicktime",
  "video/webm",
] as const;

export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_AUDIO_SIZE = 10 * 1024 * 1024; // 10MB
export const MAX_VIDEO_SIZE = 25 * 1024 * 1024; // 25MB
export const MAX_MEDIA_SIZE = MAX_VIDEO_SIZE; // 25MB overall upload limit
const MEDIA_MIMES = new Set<string>([
  ...ALLOWED_IMAGE_MIMES,
  ...ALLOWED_AUDIO_MIMES,
  ...ALLOWED_VIDEO_MIMES,
]);

export const MIMETYPE_EXTENSIONS: Record<string, string> = {
  "image/jpeg": ".jpg",
  "image/png": ".png",
  "image/gif": ".gif",
  "image/webp": ".webp",
  "audio/mpeg": ".mp3",
  "audio/mp3": ".mp3",
  "audio/mp4": ".m4a",
  "audio/m4a": ".m4a",
  "audio/x-m4a": ".m4a",
  "audio/aac": ".aac",
  "audio/ogg": ".ogg",
  "audio/wav": ".wav",
  "audio/webm": ".weba",
  "video/mp4": ".mp4",
  "video/quicktime": ".mov",
  "video/webm": ".webm",
};

export function validateMediaFile(
  file: Pick<Express.Multer.File, "mimetype" | "buffer" | "size">,
): string | null {
  const mime = file.mimetype;
  if (ALLOWED_IMAGE_MIMES.includes(mime as never)) {
    if (file.size > MAX_IMAGE_SIZE) {
      return `Imagem muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 5MB.`;
    }
    return hasValidMagicBytes(file.buffer, mime)
      ? null
      : `Conteúdo incompatível com o tipo informado: ${mime}.`;
  }

  if (ALLOWED_AUDIO_MIMES.includes(mime as never)) {
    if (file.size > MAX_AUDIO_SIZE) {
      return `Áudio muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 10MB.`;
    }
    return hasValidMagicBytes(file.buffer, mime)
      ? null
      : `Conteúdo incompatível com o tipo informado: ${mime}.`;
  }

  if (ALLOWED_VIDEO_MIMES.includes(mime as never)) {
    if (file.size > MAX_VIDEO_SIZE) {
      return `Vídeo muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: 25MB.`;
    }
    return hasValidMagicBytes(file.buffer, mime)
      ? null
      : `Conteúdo incompatível com o tipo informado: ${mime}.`;
  }

  return `Tipo de arquivo não suportado: ${mime}. Aceitos: Imagens (JPEG, PNG, WebP, GIF), Áudio (MP3, M4A, AAC, OGG, WAV), Vídeo (MP4, MOV, WebM).`;
}

export function validateImageFile(
  file: Express.Multer.File,
  maxSizeBytes: number = MAX_IMAGE_SIZE,
): string | null {
  if (
    !ALLOWED_IMAGE_MIMES.includes(
      file.mimetype as (typeof ALLOWED_IMAGE_MIMES)[number],
    )
  ) {
    return `Formato de imagem não suportado: ${file.mimetype}. Use JPEG, PNG, WebP ou GIF.`;
  }
  if (file.size > maxSizeBytes) {
    return `Imagem muito grande (${(file.size / 1024 / 1024).toFixed(1)}MB). Máximo: ${(maxSizeBytes / 1024 / 1024).toFixed(0)}MB.`;
  }
  if (!hasValidMagicBytes(file.buffer, file.mimetype)) {
    return `Conteúdo incompatível com o tipo informado: ${file.mimetype}.`;
  }
  return null;
}

export function hasValidMagicBytes(
  buffer: Buffer | undefined,
  mime: string,
): boolean {
  if (!MEDIA_MIMES.has(mime) || !buffer) return false;
  const startsWith = (...bytes: number[]) =>
    bytes.every((byte, index) => buffer[index] === byte);
  if (mime === "image/jpeg") return startsWith(0xff, 0xd8, 0xff);
  if (mime === "image/png")
    return startsWith(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a);
  if (mime === "image/gif")
    return (
      buffer.subarray(0, 6).toString("ascii") === "GIF87a" ||
      buffer.subarray(0, 6).toString("ascii") === "GIF89a"
    );
  if (mime === "image/webp")
    return (
      buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
      buffer.subarray(8, 12).toString("ascii") === "WEBP"
    );
  if (mime === "audio/mpeg" || mime === "audio/mp3") {
    return (
      buffer.subarray(0, 3).toString("ascii") === "ID3" ||
      (buffer[0] === 0xff && (buffer[1] & 0xe0) === 0xe0)
    );
  }
  if (mime === "audio/aac") {
    return buffer[0] === 0xff && (buffer[1] & 0xf6) === 0xf0;
  }
  if (mime === "audio/ogg") {
    return buffer.subarray(0, 4).toString("ascii") === "OggS";
  }
  if (mime === "audio/wav") {
    return (
      buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
      buffer.subarray(8, 12).toString("ascii") === "WAVE"
    );
  }
  if (mime === "video/webm" || mime === "audio/webm") {
    return startsWith(0x1a, 0x45, 0xdf, 0xa3);
  }
  if (
    mime === "video/mp4" ||
    mime === "video/quicktime" ||
    mime === "audio/mp4" ||
    mime === "audio/m4a" ||
    mime === "audio/x-m4a"
  ) {
    return buffer.subarray(4, 8).toString("ascii") === "ftyp";
  }
  return false;
}
