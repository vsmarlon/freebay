import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { MIMETYPE_EXTENSIONS } from './image-upload.utils';

export const UPLOAD_CONTEXTS = [
  'avatar',
  'banner',
  'product',
  'post',
  'story',
  'review',
  'chat',
  'background',
] as const;

export type UploadContext = (typeof UPLOAD_CONTEXTS)[number];

export function saveUpload(
  file: { mimetype: string; buffer: Buffer },
  context: UploadContext,
): string {
  const dir = join(process.cwd(), 'uploads', context);
  mkdirSync(dir, { recursive: true });

  const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
  const filename = `${uuidv4()}${ext}`;
  writeFileSync(join(dir, filename), file.buffer);

  return `/uploads/${context}/${filename}`;
}
