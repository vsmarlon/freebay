export function formatMoney(cents: number, locale: 'pt-BR' | 'en'): string { if (!Number.isSafeInteger(cents)) throw new TypeError('Money must be integer cents'); return new Intl.NumberFormat(locale === 'pt-BR' ? 'pt-BR' : 'en-US', { style: 'currency', currency: 'BRL' }).format(cents / 100); }
export function parseMoney(input: string): number {
  const value = input.trim().replace(/\u00a0/g, ' ').replace(/^(-?)\s*(?:R\$|\$)\s*/, '$1').replace(/\s/g, '');
  const valid = /^-?\d+$/.test(value) || /^-?\d+[,.]\d{1,2}$/.test(value) || /^-?\d{1,3}(?:\.\d{3})+,\d{1,2}$/.test(value) || /^-?\d{1,3}(?:,\d{3})+\.\d{1,2}$/.test(value);
  if (!valid) throw new TypeError('Invalid money amount');
  const decimal = value.match(/[,.](\d{1,2})$/);
  const whole = (decimal ? value.slice(0, decimal.index) : value).replace(/[.,]/g, '');
  const cents = Number(`${whole}${decimal ? decimal[1].padEnd(2, '0') : '00'}`);
  if (!Number.isSafeInteger(cents)) throw new TypeError('Money amount is outside the safe range');
  return cents;
}
