import { mkdirSync, writeFileSync, rmSync, readFileSync, statSync, renameSync, readdirSync, existsSync } from 'fs';
import { randomUUID } from 'node:crypto';
import { basename, extname, join } from 'path';
import { MIMETYPE_EXTENSIONS } from './image-upload.utils';

export const PUBLIC_UPLOAD_CONTEXTS = [
  'avatar',
  'banner',
  'product',
  'post',
  'review',
] as const;

export const PRIVATE_UPLOAD_CONTEXTS = ['chat', 'background', 'story', 'privatepost', 'comment'] as const;

export const UPLOAD_CONTEXTS = [
  ...PUBLIC_UPLOAD_CONTEXTS,
  ...PRIVATE_UPLOAD_CONTEXTS,
] as const;

export type UploadContext = (typeof UPLOAD_CONTEXTS)[number];
export type PrivateUploadContext = (typeof PRIVATE_UPLOAD_CONTEXTS)[number];

export const PUBLIC_UPLOAD_ROOT = 'uploads';
export const PRIVATE_UPLOAD_ROOT = 'private-uploads';

export const STORED_FILENAME = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]{1,5}$/;

export const STORED_MEDIA_PATH =
  /^\/(media|uploads)\/[a-z]+\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]{1,5}$/;

export function isPrivateContext(context: string): context is PrivateUploadContext {
  return (PRIVATE_UPLOAD_CONTEXTS as readonly string[]).includes(context);
}

export function saveUpload(
  file: { mimetype: string; buffer: Buffer },
  context: UploadContext,
  ownerId?: string,
): string {
  const isPrivate = isPrivateContext(context);
  const root = isPrivate ? PRIVATE_UPLOAD_ROOT : PUBLIC_UPLOAD_ROOT;
  const dir = join(process.cwd(), root, context);
  mkdirSync(dir, { recursive: true });

  const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
  const filename = `${randomUUID()}${ext}`;
  const filepath = join(dir, filename);
  writeFileSync(filepath, file.buffer, { flag: 'wx' });

  if (ownerId && (context === 'chat' || context === 'background')) {
    const marker = `${filepath}.owner`;
    const temporaryMarker = `${marker}.${randomUUID()}.tmp`;
    try {
      writeFileSync(temporaryMarker, ownerId, { flag: 'wx', mode: 0o600 });
      renameSync(temporaryMarker, marker);
    } catch (error) {
      rmSync(filepath, { force: true });
      rmSync(temporaryMarker, { force: true });
      throw error;
    }
  }

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
  const filepath = join(process.cwd(), root, context, filename);
  rmSync(filepath, { force: true });
  rmSync(`${filepath}.owner`, { force: true });
  const directory = join(process.cwd(), root, context);
  for (const entry of (existsSync(directory) ? readdirSync(directory) : []).filter((name) => name.startsWith(`${filename}.owner.`) && name.endsWith('.tmp'))) {
    rmSync(join(directory, entry), { force: true });
  }
}

export function isOwnedUpload(
  url: string,
  ownerId: string,
  expectedContext: 'chat' | 'background',
): boolean {
  const match = new RegExp(`^/media/${expectedContext}/(${STORED_FILENAME.source.slice(1, -1)})$`).exec(url);
  if (!match) return false;
  const filepath = join(process.cwd(), PRIVATE_UPLOAD_ROOT, expectedContext, match[1]);
  try {
    if (!statSync(filepath).isFile()) return false;
    return readFileSync(`${filepath}.owner`, 'utf8') === ownerId;
  } catch {
    return false;
  }
}

export function copyOwnedChatUpload(url: string, sourceOwnerId: string, newOwnerId: string): string | null {
  if (!isOwnedUpload(url, sourceOwnerId, 'chat')) return null;
  const filename = url.slice('/media/chat/'.length);
  const filepath = join(process.cwd(), PRIVATE_UPLOAD_ROOT, 'chat', filename);
  return saveUpload({ mimetype: mimeForFilename(filename), buffer: readFileSync(filepath) }, 'chat', newOwnerId);
}

export function mimeForFilename(filename: string): string {
  const ext = extname(filename).toLowerCase();
  const match = Object.entries(MIMETYPE_EXTENSIONS).find(([, value]) => value === ext);
  return match ? match[0] : 'application/octet-stream';
}
