export function digitsOnly(value: string) {
  return value.replace(/\D/g, '');
}

export function formatPhone(value: string) {
  const digits = digitsOnly(value).slice(0, 11);
  if (digits.length <= 2) return digits ? `(${digits}` : '';
  const area = digits.slice(0, 2),
    number = digits.slice(2);
  if (digits.length <= 6) return `(${area}) ${number}`;
  return digits.length <= 10
    ? `(${area}) ${number.slice(0, 4)}-${number.slice(4)}`
    : `(${area}) ${number.slice(0, 5)}-${number.slice(5)}`;
}

export function validPhone(value: string) {
  const digits = digitsOnly(value);
  return digits.length === 10 || digits.length === 11;
}

export function validCpfOrCnpj(value: string) {
  const digits = digitsOnly(value);
  if (
    (digits.length !== 11 && digits.length !== 14) ||
    (/^\d+$/.test(digits) && new Set(digits).size === 1)
  )
    return false;
  const base = digits.slice(0, digits.length === 11 ? 9 : 12);
  const checkDigits = digits.slice(-2);
  const check = (input: string) => {
    const weights =
      input.length === 9
        ? [10, 9, 8, 7, 6, 5, 4, 3, 2]
        : input.length === 12
          ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
          : input.length === 10
            ? [11, 10, 9, 8, 7, 6, 5, 4, 3, 2]
            : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const remainder =
      input.split('').reduce((sum, char, index) => sum + Number(char) * weights[index], 0) % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  };
  const first = check(base);
  return String(first) === checkDigits[0] && String(check(`${base}${first}`)) === checkDigits[1];
}

export function maskCpf(value: string) {
  const digits = digitsOnly(value);
  if (digits.length === 11) return `${digits.slice(0, 3)}.***.***-${digits.slice(-2)}`;
  if (digits.length === 14) return `${digits.slice(0, 2)}.***.***/****-${digits.slice(-2)}`;
  return '***';
}
