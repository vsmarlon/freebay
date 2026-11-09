const imageMimes = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);
const maxImageBytes = 5 * 1024 * 1024;

export function validateProductImage(
  file: Pick<File, 'type' | 'size'> | null,
): 'required' | 'type' | 'size' | null {
  if (!file) return 'required';
  if (!imageMimes.has(file.type)) return 'type';
  if (file.size > maxImageBytes) return 'size';
  return null;
}

export function formatListingPriceInput(cents: number, locale: 'pt-BR' | 'en'): string {
  if (!Number.isSafeInteger(cents) || cents < 0)
    throw new TypeError('Money must be non-negative integer cents');
  const amount = BigInt(cents);
  const separator = locale === 'pt-BR' ? ',' : '.';
  return `${amount / 100n}${separator}${String(amount % 100n).padStart(2, '0')}`;
}

export function parseListingPrice(
  input: string,
  locale: 'pt-BR' | 'en',
  allowZero = false,
): number {
  const value = input
    .trim()
    .replace(/^R\$\s*/i, '')
    .replace(/\s/g, '');
  const pattern =
    locale === 'pt-BR'
      ? /^(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{1,2})?$/
      : /^(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d{1,2})?$/;
  if (!pattern.test(value)) throw new TypeError('Invalid price syntax');
  const normalized = locale === 'pt-BR' ? value.replace(/\./g, '') : value.replace(/,/g, '');
  const [whole, fraction = ''] = normalized.split(locale === 'pt-BR' ? ',' : '.');
  const cents = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0') || '0');
  if (cents > BigInt(Number.MAX_SAFE_INTEGER) || (allowZero ? cents < 0n : cents <= 0n))
    throw new TypeError('Listing price must be positive integer cents');
  return Number(cents);
}
