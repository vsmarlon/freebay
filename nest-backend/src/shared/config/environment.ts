import { parseAllowedOrigins } from '../http/origin-policy';
import { isIP } from 'node:net';

export function validateEnvironment(env: Record<string, string | undefined>): Record<string, string | undefined> {
  const nodeEnv = env.NODE_ENV ?? 'development';
  if (!['development', 'test', 'production'].includes(nodeEnv)) {
    throw new Error('NODE_ENV must be development, test, or production');
  }
  const secret = env.JWT_SECRET ?? '';
  if (
    Buffer.byteLength(secret, 'utf8') < 32 ||
    /^(.)\1+$/.test(secret) ||
    /(.{1,8})\1{3,}/.test(secret) ||
    /(?:your[-_ ].*secret|change[-_ ](?:me|this)|placeholder|example[-_ ](?:key|secret)|replace[-_ ]me|test[-_ ]secret)/i.test(secret)
  ) {
    throw new Error('JWT_SECRET must be a strong secret of at least 32 bytes');
  }
  const origins = env.ALLOWED_ORIGINS ?? env.WEB_APP_URL ?? env.WEB_ALLOWED_ORIGIN ?? 'http://localhost:3000';
  const parsedOrigins = parseAllowedOrigins(origins);
  if (parsedOrigins.length !== origins.split(',').length) throw new Error('ALLOWED_ORIGINS contains an invalid origin');
  if (nodeEnv === 'production' && parsedOrigins.some((origin) => !origin.startsWith('https://'))) {
    throw new Error('Production origins must use HTTPS');
  }
  if (nodeEnv === 'production' && !env.APP_URL) throw new Error('APP_URL must be explicitly configured in production');
  for (const name of ['APP_URL', 'WEB_APP_URL']) {
    const value = env[name];
    if (!value) continue;
    try {
      const url = new URL(value);
      if (!url.hostname || (nodeEnv === 'production' &&
        (url.protocol !== 'https:' || !parsedOrigins.includes(url.origin)))) throw new Error();
    } catch {
      throw new Error(`${name} must be a valid configured public URL`);
    }
  }
  if (nodeEnv === 'production' && !env.REDIS_URL && !env.REDIS_HOST) {
    throw new Error('Redis configuration is required in production');
  }
  for (const name of ['JWT_EXPIRES_IN', 'JWT_REFRESH_EXPIRES_IN', 'JWT_BIOMETRIC_EXPIRES_IN']) {
    const value = env[name] ?? (name === 'JWT_EXPIRES_IN' ? '15m' : '7d');
    const match = /^(\d+)(s|m|h|d)$/.exec(value);
    const unitSeconds: Record<string, number> = { s: 1, m: 60, h: 3600, d: 86400 };
    const seconds = match ? Number(match[1]) * (unitSeconds[match[2]] ?? 0) : 0;
    if (!seconds || seconds > 30 * 24 * 60 * 60) throw new Error(`${name} must be between 1 second and 30 days`);
  }
  if (nodeEnv === 'production') {
    if (env.CPF_ENCRYPTION_KEY && env.CPF_ENCRYPTION_KEY === env.CPF_HMAC_KEY) {
      throw new Error('CPF_ENCRYPTION_KEY and CPF_HMAC_KEY must be different');
    }
    for (const name of ['CPF_ENCRYPTION_KEY', 'CPF_HMAC_KEY']) {
      const value = env[name] ?? '';
      const decoded = Buffer.from(value, 'base64');
      if (decoded.byteLength !== 32 || decoded.toString('base64') !== value) {
        throw new Error(`${name} must be configured as a canonical 32-byte base64 key`);
      }
    }
  }
  if (env.REDIS_URL !== undefined && !env.REDIS_URL.trim()) {
    throw new Error('REDIS_URL must be a valid Redis URL');
  }
  if (env.REDIS_URL) {
    try {
      const redisUrl = new URL(env.REDIS_URL);
      if (!['redis:', 'rediss:'].includes(redisUrl.protocol) || !redisUrl.hostname) throw new Error();
    } catch {
      throw new Error('REDIS_URL must be a valid Redis URL');
    }
  }
  if (env.REDIS_HOST !== undefined && !env.REDIS_HOST.trim()) {
    throw new Error('REDIS_HOST must not be empty');
  }
  if (env.REDIS_PORT !== undefined) {
    const port = Number(env.REDIS_PORT);
    if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('REDIS_PORT must be between 1 and 65535');
  }
  const proxies = env.TRUST_PROXY_CIDRS?.split(',').map((part) => part.trim()).filter(Boolean) ?? [];
  if (proxies.some((proxy) => {
    const [address, prefix, extra] = proxy.split('/');
    const version = isIP(address);
    return !version || extra !== undefined || (prefix !== undefined &&
      (!/^\d+$/.test(prefix) || Number(prefix) < 1 || Number(prefix) > (version === 4 ? 32 : 128)));
  })) throw new Error('TRUST_PROXY_CIDRS must contain valid IP addresses or CIDRs');
  return env;
}
