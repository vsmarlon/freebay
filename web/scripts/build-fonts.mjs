import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import subsetFont from 'subset-font';

/**
 * Subsets the two variable display/text fonts to latin-1 coverage and writes
 * woff2 sources into app/fonts/. Regenerate with: node scripts/build-fonts.mjs
 * Output files are committed (deterministic, ~90 kB total) so app builds do not
 * depend on the subsetting toolchain.
 */
const sources = [
  {
    input: '../fonts/Inter[opsz,wght].ttf',
    output: '../app/fonts/inter-var-latin.woff2',
  },
  {
    input: '../fonts/SpaceGrotesk[wght].ttf',
    output: '../app/fonts/space-grotesk-var-latin.woff2',
  },
];

// ponytail: text-driven subsetting, latin-1 + common punctuation/currency; add codepoints here if a catalog needs more.
const text = String.fromCharCode(...Array.from({ length: 0x7f - 0x20 }, (_, i) => 0x20 + i))
  + String.fromCharCode(...Array.from({ length: 0xff - 0xa0 }, (_, i) => 0xa0 + i))
  + '–—‘’“”…€™°·‘ˆ˜’';

for (const { input, output } of sources) {
  const original = readFileSync(join(import.meta.dirname, input));
  const buffer = await subsetFont(original, text, { targetFormat: 'woff2' });
  const out = join(import.meta.dirname, output);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, buffer);
  const variable = buffer.indexOf('fvar') >= 0 ? 'variable ok' : '⚠ NO fvar axis';
  console.log(`${input} ${(original.length / 1024).toFixed(1)} kB → ${output} ${(buffer.length / 1024).toFixed(1)} kB (${variable})`);
}

console.log(`glyph text ${text.length} chars`);
