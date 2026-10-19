const secretKey = '(password|passwd|senha|token|access[_ -]?token|refresh[_ -]?token|secret|api[_ -]?key|authorization|cookie|otp|verification[ _-]?code|c[oó]digo[ _-]?(?:de[ _-]?)?verifica[cç][aã]o)';
const quotedSecretAssignment = new RegExp(`(["'])?\\b${secretKey}\\b\\1?\\s*:\\s*(["'])(?:\\\\.|(?!\\3)[^\\\\])*\\3`, 'gi');
const secretAssignment = new RegExp(`\\b${secretKey}\\b\\s*[:=]\\s*(?:Bearer\\s+)?[^\\s,;]+`, 'gi');
const bearerCredential = /\bBearer\s+[A-Za-z0-9._~+/-]+=*/gi;
const jwtCredential = /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g;
const cardNumber = /(?<!\d)(?:\d[ -]?){13,19}(?!\d)/g;

export function redactSensitiveDiagnostics(value: string) {
  return value
    .replace(quotedSecretAssignment, '$2="[REDACTED]"')
    .replace(secretAssignment, '$1=[REDACTED]')
    .replace(bearerCredential, 'Bearer [REDACTED]')
    .replace(jwtCredential, '[REDACTED JWT]')
    .replace(cardNumber, '[REDACTED CARD NUMBER]');
}
