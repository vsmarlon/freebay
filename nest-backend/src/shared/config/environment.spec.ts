import { validateEnvironment } from './environment';

describe('environment validation', () => {
  it('rejects weak JWT secrets and production HTTP origins', () => {
    expect(() => validateEnvironment({ JWT_SECRET: 'short' })).toThrow('JWT_SECRET');
    expect(() => validateEnvironment({ JWT_SECRET: 'abcdefghabcdefghabcdefghabcdefgh' })).toThrow('JWT_SECRET');
    expect(() => validateEnvironment({
      NODE_ENV: 'production', JWT_SECRET: 'a9Y!qP4#sK7@vM2$xR8^cN5&bL1!wZ6?',
      ALLOWED_ORIGINS: 'http://app.example', REDIS_URL: 'redis://localhost:6379',
    })).toThrow('HTTPS');
  });

  it('requires production CPF keys and rejects untrusted proxy syntax and excessive token TTLs', () => {
    const production = {
      NODE_ENV: 'production',
      JWT_SECRET: 'a9Y!qP4#sK7@vM2$xR8^cN5&bL1!wZ6?',
      ALLOWED_ORIGINS: 'https://app.example',
      APP_URL: 'https://app.example',
      REDIS_URL: 'rediss://redis.example:6380',
      CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
      CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
    };
    expect(() => validateEnvironment({ ...production, CPF_HMAC_KEY: undefined })).toThrow('CPF_HMAC_KEY');
    expect(() => validateEnvironment({ ...production, TRUST_PROXY_CIDRS: 'true' })).toThrow('TRUST_PROXY_CIDRS');
    expect(() => validateEnvironment({ ...production, JWT_BIOMETRIC_EXPIRES_IN: '31d' })).toThrow('JWT_BIOMETRIC_EXPIRES_IN');
    expect(validateEnvironment(production)).toBe(production);
  });

  it('rejects identical CPF encryption and lookup keys', () => {
    const sameKey = Buffer.alloc(32, 7).toString('base64');
    expect(() => validateEnvironment({
      NODE_ENV: 'production',
      JWT_SECRET: 'a9Y!qP4#sK7@vM2$xR8^cN5&bL1!wZ6?',
      ALLOWED_ORIGINS: 'https://app.example',
      APP_URL: 'https://app.example',
      REDIS_URL: 'rediss://redis.example:6380',
      CPF_ENCRYPTION_KEY: sameKey,
      CPF_HMAC_KEY: sameKey,
    })).toThrow('must be different');
  });

  it.each(['redis:///', 'redis://:6379', 'redis://redis.example:70000'])('rejects malformed Redis URL %s', (url) => {
    expect(() => validateEnvironment({ JWT_SECRET: 'a9Y!qP4#sK7@vM2$xR8^cN5&bL1!wZ6?', REDIS_URL: url })).toThrow('REDIS_URL');
  });

  it('requires public production redirect URLs to be trusted HTTPS origins', () => {
    const base = {
      NODE_ENV: 'production',
      JWT_SECRET: 'a9Y!qP4#sK7@vM2$xR8^cN5&bL1!wZ6?',
      ALLOWED_ORIGINS: 'https://app.example',
      REDIS_URL: 'rediss://redis.example:6380',
      CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
      CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
    };
    expect(() => validateEnvironment({ ...base, APP_URL: 'http://app.example' })).toThrow('APP_URL');
    expect(() => validateEnvironment({ ...base, APP_URL: 'https://outside.example' })).toThrow('APP_URL');
    expect(() => validateEnvironment({ ...base, APP_URL: undefined })).toThrow('APP_URL');
  });
});
