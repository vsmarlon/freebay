import { PublicationMediaType } from '@prisma/client';
import { parsePublicationMedia, validatePublicationMediaFiles } from './publication-media';

describe('parsePublicationMedia', () => {
  it('accepts ordered mixed media and semantic hotspots', () => {
    expect(parsePublicationMedia(JSON.stringify([
      { fileIndex: 0, type: 'IMAGE', altText: 'Front view' },
      {
        fileIndex: 1, thumbnailFileIndex: 2, type: 'VIDEO', durationMs: 3000,
        coverTimestampMs: 1000,
        hotspots: [{
          kind: 'LINK', payload: { listingId: '123e4567-e89b-12d3-a456-426614174000' },
          centerX: .5, centerY: .5, width: .2, height: .1, rotation: 0,
          startMs: 500, endMs: 2500,
        }],
      },
    ]), 3)).toEqual([
      { fileIndex: 0, type: PublicationMediaType.IMAGE, altText: 'Front view', hotspots: [] },
      expect.objectContaining({ fileIndex: 1, thumbnailFileIndex: 2, type: PublicationMediaType.VIDEO }),
    ]);
  });

  it('accepts the maximum collection size', () => {
    const metadata = Array.from({ length: 10 }, (_, fileIndex) => ({ fileIndex, type: 'IMAGE' }));

    expect(parsePublicationMedia(JSON.stringify(metadata), 10)).toHaveLength(10);
  });

  it.each([
    ['duplicate files', [{ fileIndex: 0, type: 'IMAGE' }, { fileIndex: 0, type: 'IMAGE' }], 2],
    ['video without thumbnail', [{ fileIndex: 0, type: 'VIDEO', durationMs: 1000 }], 1],
    ['external link', [{ fileIndex: 0, type: 'IMAGE', hotspots: [{ kind: 'LINK', payload: { listingId: 'https://evil.test' }, centerX: .5, centerY: .5, width: .2, height: .2, rotation: 0 }] }], 1],
    ['11 items', Array.from({ length: 11 }, (_, fileIndex) => ({ fileIndex, type: 'IMAGE' })), 11],
    ['alt text over 500 characters', [{ fileIndex: 0, type: 'IMAGE', altText: 'a'.repeat(501) }], 1],
    ['more than 20 hotspots', [{ fileIndex: 0, type: 'IMAGE', hotspots: Array.from({ length: 21 }) }], 1],
    ['geometry outside normalized bounds', [{ fileIndex: 0, type: 'IMAGE', hotspots: [{ kind: 'LOCATION', payload: { label: 'Lisbon' }, centerX: 1.1, centerY: .5, width: .2, height: .2, rotation: 0 }] }], 1],
    ['empty location label', [{ fileIndex: 0, type: 'IMAGE', hotspots: [{ kind: 'LOCATION', payload: { label: ' ' }, centerX: .5, centerY: .5, width: .2, height: .2, rotation: 0 }] }], 1],
    ['video cover after its duration', [{ fileIndex: 0, thumbnailFileIndex: 1, type: 'VIDEO', durationMs: 1000, coverTimestampMs: 1001 }], 2],
    ['image cover timestamp', [{ fileIndex: 0, type: 'IMAGE', coverTimestampMs: 0 }], 1],
    ['timed image hotspot', [{ fileIndex: 0, type: 'IMAGE', hotspots: [{ kind: 'LOCATION', payload: { label: 'Lisbon' }, centerX: .5, centerY: .5, width: .2, height: .2, rotation: 0, startMs: 0, endMs: 0 }] }], 1],
    ['an unreferenced upload', [{ fileIndex: 0, type: 'IMAGE' }], 2],
  ])('rejects %s', (_, metadata, fileCount) => {
    expect(() => parsePublicationMedia(JSON.stringify(metadata), fileCount)).toThrow();
  });

  it('requires main files and video thumbnails to match their declared roles', () => {
    const descriptors = parsePublicationMedia(JSON.stringify([
      { fileIndex: 0, thumbnailFileIndex: 1, type: 'VIDEO', durationMs: 1000 },
    ]), 2);

    expect(() => validatePublicationMediaFiles(descriptors, [
      { mimetype: 'image/jpeg' },
      { mimetype: 'image/png' },
    ])).toThrow('does not match VIDEO');
    expect(() => validatePublicationMediaFiles(descriptors, [
      { mimetype: 'video/mp4' },
      { mimetype: 'video/mp4' },
    ])).toThrow('is not a valid thumbnail image');
  });
});
