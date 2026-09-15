import { hasValidMagicBytes, validateMediaFile } from "./image-upload.utils";

describe("media upload validation", () => {
  it("accepts a JPEG signature for a JPEG claim", () => {
    expect(
      hasValidMagicBytes(Buffer.from([0xff, 0xd8, 0xff]), "image/jpeg"),
    ).toBe(true);
  });

  it("rejects content whose signature does not match the claimed MIME", () => {
    const file = {
      mimetype: "image/png",
      buffer: Buffer.from([0xff, 0xd8, 0xff]),
      size: 3,
    };

    expect(validateMediaFile(file)).toContain("Conteúdo incompatível");
  });

  it("recognizes WebP, MP4, QuickTime, and WebM container markers", () => {
    expect(hasValidMagicBytes(Buffer.from("RIFF1234WEBP"), "image/webp")).toBe(
      true,
    );
    expect(hasValidMagicBytes(Buffer.from("0000ftypisom"), "video/mp4")).toBe(
      true,
    );
    expect(
      hasValidMagicBytes(Buffer.from("0000ftypqt  "), "video/quicktime"),
    ).toBe(true);
    expect(
      hasValidMagicBytes(Buffer.from([0x1a, 0x45, 0xdf, 0xa3]), "video/webm"),
    ).toBe(true);
  });

  it("validates supported audio signatures", () => {
    expect(hasValidMagicBytes(Buffer.from("ID3test"), "audio/mpeg")).toBe(
      true,
    );
    expect(hasValidMagicBytes(Buffer.from("OggStest"), "audio/ogg")).toBe(
      true,
    );
    expect(hasValidMagicBytes(Buffer.from("RIFF1234WAVE"), "audio/wav")).toBe(
      true,
    );
    expect(
      validateMediaFile({
        mimetype: "audio/mpeg",
        buffer: Buffer.from("not audio"),
        size: 9,
      }),
    ).toContain("Conteúdo incompatível");
  });
});
