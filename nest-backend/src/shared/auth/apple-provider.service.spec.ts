import { ConfigService } from '@nestjs/config';
import { createHash, generateKeyPairSync, sign } from 'crypto';
import { AppleProviderService } from './apple-provider.service';

const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = publicKey.export({ format: 'jwk' });
const b64 = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString('base64url');
const identityJwt = (claims: Record<string, unknown>, header: Record<string, unknown> = { alg: 'RS256', kid: 'key-1' }): string => {
  const unsigned = `${b64(header)}.${b64(claims)}`;
  return `${unsigned}.${sign('RSA-SHA256', Buffer.from(unsigned), privateKey).toString('base64url')}`;
};

describe('AppleProviderService', () => {
  it('rejects token encryption keys that are not exactly 32 bytes', () => {
    const config = new ConfigService({ APPLE_TOKEN_ENCRYPTION_KEY: Buffer.alloc(31).toString('base64') });
    expect(() => new AppleProviderService(config).encryptRefreshToken('token'))
      .toThrow('APPLE_TOKEN_ENCRYPTION_KEY must decode to exactly 32 bytes');
  });

  it('encrypts refresh tokens so ciphertext does not contain the source token', () => {
    const config = new ConfigService({ APPLE_TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64') });
    const ciphertext = new AppleProviderService(config).encryptRefreshToken('apple-refresh-token');
    expect(ciphertext).not.toContain('apple-refresh-token');
    expect(ciphertext.split('.')).toHaveLength(3);
  });

  describe('identity token verification', () => {
    let fetchSpy: jest.SpyInstance;
    const config = new ConfigService({ APPLE_CLIENT_ID: 'com.example.app' });
    const now = Math.floor(Date.now() / 1000);
    const claims = {
      iss: 'https://appleid.apple.com', aud: 'com.example.app', sub: 'apple-user', exp: now + 60,
      nonce: createHash('sha256').update('raw-nonce').digest('hex'),
      email: 'person@example.com', email_verified: 'true',
    };

    beforeEach(() => {
      fetchSpy = jest.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(JSON.stringify({ keys: [{
        kid: 'key-1', kty: 'RSA', alg: 'RS256', use: 'sig', n: jwk.n, e: jwk.e,
      }] }), { status: 200, headers: { 'content-type': 'application/json' } }));
    });
    afterEach(() => fetchSpy.mockRestore());

    it('accepts a correctly signed, scoped, unexpired token with the nonce hash', async () => {
      const identity = await new AppleProviderService(config).verifyIdentityToken(identityJwt(claims), 'raw-nonce');
      expect(identity).toEqual({ sub: 'apple-user', email: 'person@example.com', emailVerified: true, nonce: claims.nonce });
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    it.each<[string, Record<string, unknown>]>([
      ['expired', { exp: now }],
      ['wrong issuer', { iss: 'https://attacker.example' }],
      ['wrong audience', { aud: 'another-client' }],
      ['future not-before', { nbf: now + 60 }],
    ])('rejects a signed token with %s claims', async (_label, override) => {
      await expect(new AppleProviderService(config).verifyIdentityToken(identityJwt({ ...claims, ...override }), 'raw-nonce'))
        .rejects.toThrow('Invalid Apple identity token');
    });

    it('rejects a validly signed token bound to a different nonce', async () => {
      await expect(new AppleProviderService(config).verifyIdentityToken(identityJwt(claims), 'other-nonce'))
        .rejects.toThrow('Invalid Apple identity token');
    });

    it('rejects a forged signature even when the claims otherwise look valid', async () => {
      const token = identityJwt({ ...claims, sub: 'attacker' });
      const forged = `${token.slice(0, token.lastIndexOf('.') + 1)}${Buffer.alloc(256).toString('base64url')}`;
      await expect(new AppleProviderService(config).verifyIdentityToken(forged, 'raw-nonce'))
        .rejects.toThrow('Invalid Apple identity token');
    });

    it('rejects an unsupported signing algorithm before accepting the claims', async () => {
      await expect(new AppleProviderService(config).verifyIdentityToken(identityJwt(claims, { alg: 'none', kid: 'key-1' }), 'raw-nonce'))
        .rejects.toThrow('Invalid Apple identity token');
      expect(fetchSpy).not.toHaveBeenCalled();
    });
  });
});
