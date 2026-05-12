export function isValidCpf(cpf: string): boolean {
  const digits = cpf.replace(/\D/g, '');
  if (digits.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(digits)) return false;

  let sum = 0;
  for (let i = 0; i < 9; i++) sum += parseInt(digits[i]) * (10 - i);
  let remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  if (remainder !== parseInt(digits[9])) return false;

  sum = 0;
  for (let i = 0; i < 10; i++) sum += parseInt(digits[i]) * (11 - i);
  remainder = (sum * 10) % 11;
  if (remainder === 10 || remainder === 11) remainder = 0;
  return remainder === parseInt(digits[10]);
}

export function isValidCnpj(cnpj: string): boolean {
  // Strip formatting — support both legacy numeric and new alphanumeric CNPJ (2026+)
  const raw = cnpj.replace(/[.\-/]/g, '').toUpperCase();
  if (raw.length !== 14) return false;
  if (/^(.)\1{13}$/.test(raw)) return false;

  // Convert each char to its numeric value: digits → digit, letters → ASCII - 48
  const charVal = (c: string) => (c >= '0' && c <= '9' ? parseInt(c) : c.charCodeAt(0) - 48);

  const mod = (n: number) => {
    const r = n % 11;
    return r < 2 ? 0 : 11 - r;
  };

  const calc = (s: string, weights: number[]) =>
    weights.reduce((sum, w, i) => sum + charVal(s[i]) * w, 0);

  const r1 = mod(calc(raw, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]));
  if (r1 !== parseInt(raw[12])) return false;

  const r2 = mod(calc(raw, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]));
  return r2 === parseInt(raw[13]);
}

export function isValidCpfOrCnpj(value: string): boolean {
  const digits = value.replace(/\D/g, '');
  const alphanumRaw = value.replace(/[.\-/]/g, '');
  if (digits.length === 11) return isValidCpf(digits);
  if (alphanumRaw.length === 14) return isValidCnpj(value);
  return false;
}
