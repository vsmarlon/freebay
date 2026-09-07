import { mkdirSync, writeFileSync, rmSync } from 'fs';
import { basename, extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { MIMETYPE_EXTENSIONS } from './image-upload.utils';

export const PUBLIC_UPLOAD_CONTEXTS = [
  'avatar',
  'banner',
  'product',
  'post',
  'story',
  'review',
] as const;

export const PRIVATE_UPLOAD_CONTEXTS = ['chat', 'background'] as const;

export const UPLOAD_CONTEXTS = [
  ...PUBLIC_UPLOAD_CONTEXTS,
  ...PRIVATE_UPLOAD_CONTEXTS,
] as const;

export type UploadContext = (typeof UPLOAD_CONTEXTS)[number];
export type PrivateUploadContext = (typeof PRIVATE_UPLOAD_CONTEXTS)[number];

export const PUBLIC_UPLOAD_ROOT = 'uploads';
export const PRIVATE_UPLOAD_ROOT = 'private-uploads';

export const STORED_FILENAME = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]{1,5}$/;

export function isPrivateContext(context: string): context is PrivateUploadContext {
  return (PRIVATE_UPLOAD_CONTEXTS as readonly string[]).includes(context);
}

export function saveUpload(
  file: { mimetype: string; buffer: Buffer },
  context: UploadContext,
): string {
  const isPrivate = isPrivateContext(context);
  const root = isPrivate ? PRIVATE_UPLOAD_ROOT : PUBLIC_UPLOAD_ROOT;
  const dir = join(process.cwd(), root, context);
  mkdirSync(dir, { recursive: true });

  const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
  const filename = `${uuidv4()}${ext}`;
  writeFileSync(join(dir, filename), file.buffer);

  return isPrivate
    ? `/media/${context}/${filename}`
    : `/uploads/${context}/${filename}`;
}

export function deleteUpload(url: string | null | undefined): void {
  if (!url) return;

  const match = /^\/(uploads|media)\/([a-z]+)\/([^/?#]+)$/.exec(url);
  if (!match) return;

  const [, prefix, context, filename] = match;
  if (!(UPLOAD_CONTEXTS as readonly string[]).includes(context)) return;
  if (basename(filename) !== filename || !STORED_FILENAME.test(filename)) return;

  const root = prefix === 'media' ? PRIVATE_UPLOAD_ROOT : PUBLIC_UPLOAD_ROOT;
  rmSync(join(process.cwd(), root, context, filename), { force: true });
}

export function mimeForFilename(filename: string): string {
  const ext = extname(filename).toLowerCase();
  const match = Object.entries(MIMETYPE_EXTENSIONS).find(([, value]) => value === ext);
  return match ? match[0] : 'application/octet-stream';
}
