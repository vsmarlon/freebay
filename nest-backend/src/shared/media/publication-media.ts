import { PublicationMediaType } from '@prisma/client';
import { ALLOWED_IMAGE_MIMES, ALLOWED_VIDEO_MIMES } from '@/shared/utils/image-upload.utils';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export type MediaHotspot = {
  kind: 'LINK' | 'LOCATION';
  payload: { listingId: string } | { label: string };
  centerX: number;
  centerY: number;
  width: number;
  height: number;
  rotation: number;
  startMs?: number;
  endMs?: number;
};

export type PublicationMediaDescriptor = {
  fileIndex: number;
  thumbnailFileIndex?: number;
  type: PublicationMediaType;
  altText?: string;
  durationMs?: number;
  coverTimestampMs?: number;
  hotspots: MediaHotspot[];
};

export type PublicationMediaInput = Omit<PublicationMediaDescriptor, 'fileIndex' | 'thumbnailFileIndex'> & {
  url: string;
  thumbnailUrl?: string;
  blurHash?: string;
};

export type PublicationMediaResponse = {
  id: string;
  url: string;
  thumbnailUrl: string | null;
  type: PublicationMediaType;
  blurHash?: string;
  altText: string | null;
  hotspots: unknown;
  durationMs: number | null;
  coverTimestampMs: number | null;
  order: number;
};

export function parsePublicationMedia(
  raw: unknown,
  fileCount: number,
  maxItems = 10,
): PublicationMediaDescriptor[] {
  if (typeof raw !== 'string') throw new Error('mediaMetadata is required');
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    throw new Error('mediaMetadata must be valid JSON');
  }
  if (!Array.isArray(value) || value.length < 1 || value.length > maxItems) {
    throw new Error(`mediaMetadata must contain 1 to ${maxItems} items`);
  }

  const used = new Set<number>();
  const descriptors = value.map((entry, order) => {
    if (!isObject(entry)) throw new Error(`mediaMetadata[${order}] is invalid`);
    const fileIndex = integer(entry.fileIndex, 0, fileCount - 1, `mediaMetadata[${order}].fileIndex`);
    if (used.has(fileIndex)) throw new Error('Each media file can be used only once');
    used.add(fileIndex);

    const type = entry.type;
    if (type !== PublicationMediaType.IMAGE && type !== PublicationMediaType.VIDEO) {
      throw new Error(`mediaMetadata[${order}].type is invalid`);
    }
    const thumbnailFileIndex = entry.thumbnailFileIndex == null
      ? undefined
      : integer(entry.thumbnailFileIndex, 0, fileCount - 1, `mediaMetadata[${order}].thumbnailFileIndex`);
    if (thumbnailFileIndex != null) {
      if (used.has(thumbnailFileIndex)) throw new Error('Each media file can be used only once');
      used.add(thumbnailFileIndex);
    }
    if (type === PublicationMediaType.VIDEO && thumbnailFileIndex == null) {
      throw new Error(`mediaMetadata[${order}] video requires a thumbnail`);
    }
    if (type === PublicationMediaType.IMAGE && thumbnailFileIndex != null) {
      throw new Error(`mediaMetadata[${order}] image cannot have a thumbnail file`);
    }

    const altText = optionalText(entry.altText, 500, `mediaMetadata[${order}].altText`);
    const durationMs = optionalInteger(entry.durationMs, 1, 60 * 60 * 1000, `mediaMetadata[${order}].durationMs`);
    const coverTimestampMs = optionalInteger(
      entry.coverTimestampMs,
      0,
      durationMs ?? 60 * 60 * 1000,
      `mediaMetadata[${order}].coverTimestampMs`,
    );
    if (type === PublicationMediaType.VIDEO && durationMs == null) {
      throw new Error(`mediaMetadata[${order}] video requires durationMs`);
    }
    if (type === PublicationMediaType.IMAGE && coverTimestampMs != null) {
      throw new Error(`mediaMetadata[${order}] image cannot have coverTimestampMs`);
    }
    const hotspots = parseHotspots(entry.hotspots, type, durationMs, order);
    return {
      fileIndex,
      ...(thumbnailFileIndex == null ? {} : { thumbnailFileIndex }),
      type,
      ...(altText == null ? {} : { altText }),
      ...(durationMs == null ? {} : { durationMs }),
      ...(coverTimestampMs == null ? {} : { coverTimestampMs }),
      hotspots,
    };
  });
  if (used.size !== fileCount) throw new Error('Every uploaded file must be referenced exactly once');
  return descriptors;
}

export function validatePublicationMediaFiles(
  descriptors: readonly PublicationMediaDescriptor[],
  files: readonly Pick<Express.Multer.File, 'mimetype'>[],
): void {
  for (const descriptor of descriptors) {
    const file = files[descriptor.fileIndex];
    const mainMatches = descriptor.type === PublicationMediaType.IMAGE
      ? file != null && file.mimetype !== 'image/gif' && ALLOWED_IMAGE_MIMES.includes(file.mimetype as never)
      : file != null && ALLOWED_VIDEO_MIMES.includes(file.mimetype as never);
    if (!mainMatches) throw new Error(`File ${descriptor.fileIndex} does not match ${descriptor.type}`);
    if (descriptor.thumbnailFileIndex != null) {
      const thumbnail = files[descriptor.thumbnailFileIndex];
      if (!thumbnail || thumbnail.mimetype === 'image/gif' || !ALLOWED_IMAGE_MIMES.includes(thumbnail.mimetype as never)) {
        throw new Error(`File ${descriptor.thumbnailFileIndex} is not a valid thumbnail image`);
      }
    }
  }
}

function parseHotspots(
  value: unknown,
  mediaType: PublicationMediaType,
  durationMs: number | undefined,
  mediaIndex: number,
): MediaHotspot[] {
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > 20) {
    throw new Error(`mediaMetadata[${mediaIndex}].hotspots is invalid`);
  }
  return value.map((hotspot, index) => {
    const at = `mediaMetadata[${mediaIndex}].hotspots[${index}]`;
    if (!isObject(hotspot) || (hotspot.kind !== 'LINK' && hotspot.kind !== 'LOCATION') || !isObject(hotspot.payload)) {
      throw new Error(`${at} is invalid`);
    }
    let payload: MediaHotspot['payload'];
    if (hotspot.kind === 'LINK') {
      const listingId = requiredText(hotspot.payload.listingId, 36, `${at}.payload.listingId`);
      if (!UUID.test(listingId)) throw new Error(`${at}.payload.listingId is invalid`);
      payload = { listingId };
    } else {
      payload = { label: requiredText(hotspot.payload.label, 100, `${at}.payload.label`) };
    }
    if (mediaType === PublicationMediaType.IMAGE && (hotspot.startMs != null || hotspot.endMs != null)) {
      throw new Error(`${at} image hotspot cannot have startMs or endMs`);
    }
    const startMs = optionalInteger(hotspot.startMs, 0, durationMs ?? 0, `${at}.startMs`);
    const endMs = optionalInteger(hotspot.endMs, startMs ?? 0, durationMs ?? 0, `${at}.endMs`);
    if ((startMs == null) !== (endMs == null)) throw new Error(`${at} requires both startMs and endMs`);
    return {
      kind: hotspot.kind,
      payload,
      centerX: finite(hotspot.centerX, 0, 1, `${at}.centerX`),
      centerY: finite(hotspot.centerY, 0, 1, `${at}.centerY`),
      width: finite(hotspot.width, 0.001, 1, `${at}.width`),
      height: finite(hotspot.height, 0.001, 1, `${at}.height`),
      rotation: finite(hotspot.rotation, -Math.PI * 2, Math.PI * 2, `${at}.rotation`),
      ...(startMs == null ? {} : { startMs, endMs: endMs! }),
    };
  });
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value != null && !Array.isArray(value);
}

function finite(value: unknown, min: number, max: number, name: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) throw new Error(`${name} is invalid`);
  return value;
}

function integer(value: unknown, min: number, max: number, name: string): number {
  const number = finite(value, min, max, name);
  if (!Number.isInteger(number)) throw new Error(`${name} is invalid`);
  return number;
}

function optionalInteger(value: unknown, min: number, max: number, name: string): number | undefined {
  return value == null ? undefined : integer(value, min, max, name);
}

function requiredText(value: unknown, max: number, name: string): string {
  if (typeof value !== 'string' || value.trim().length < 1 || value.trim().length > max) throw new Error(`${name} is invalid`);
  return value.trim();
}

function optionalText(value: unknown, max: number, name: string): string | undefined {
  return value == null || value === '' ? undefined : requiredText(value, max, name);
}
