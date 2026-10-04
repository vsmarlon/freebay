import { encode } from 'blurhash';
import sharp from 'sharp';

export const MAX_BLURHASH_LENGTH = 166;
const BLURHASH_ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

export function isValidBlurHash(value: unknown): value is string {
  if (typeof value !== 'string' || value.length < 6 || value.length > MAX_BLURHASH_LENGTH) return false;
  for (const character of value) {
    if (!BLURHASH_ALPHABET.includes(character)) return false;
  }
  const sizeFlag = BLURHASH_ALPHABET.indexOf(value[0]);
  const componentsX = sizeFlag % 9 + 1;
  const componentsY = Math.floor(sizeFlag / 9) + 1;
  return value.length === 4 + 2 * componentsX * componentsY;
}

export async function generateImageBlurHash(buffer: Buffer): Promise<string | undefined> {
  try {
    const { data, info } = await sharp(buffer)
      .rotate()
      .resize(32, 32, { fit: 'inside' })
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    return encode(new Uint8ClampedArray(data), info.width, info.height, 4, 3);
  } catch {
    return undefined;
  }
}
