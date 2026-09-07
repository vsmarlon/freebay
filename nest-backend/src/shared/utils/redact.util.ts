export type JsonValue =
  | string
  | number
  | boolean
  | null
  | { [key: string]: JsonValue }
  | JsonValue[];

const SENSITIVE_KEYS = new Set([
  'password',
  'newPassword',
  'currentPassword',
  'confirmPassword',
  'token',
  'refreshToken',
  'biometricToken',
  'idToken',
  'authorization',
  'code',
  'cpf',
  'cpfHash',
  'clientSecret',
  'paymentIntentClientSecret',
]);

export function isSensitiveKey(key: string): boolean {
  return SENSITIVE_KEYS.has(key) || key.toLowerCase().includes('secret');
}

export function redact(value: unknown, depth = 0): JsonValue {
  if (depth > 5) return '[NESTED]';

  if (Array.isArray(value)) {
    if (value.length > 20) return `[Array(${value.length})]`;
    return value.map((item) => redact(item, depth + 1));
  }

  if (!value || typeof value !== 'object') {
    if (typeof value === 'string' && value.startsWith('data:image/')) {
      return '[IMAGE_DATA_URI]';
    }
    if (
      typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean' ||
      value === null
    ) {
      return value;
    }
    return String(value);
  }

  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>).map(([key, nested]) => [
      key,
      isSensitiveKey(key) ? '[REDACTED]' : redact(nested, depth + 1),
    ]),
  );
}
