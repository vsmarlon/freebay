import { createCipheriv, createDecipheriv, createHash, createPublicKey, createSign, JsonWebKey, KeyObject, randomBytes, verify } from 'crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys';
const APPLE_TOKEN_URL = 'https://appleid.apple.com/auth/token';
const APPLE_JWKS_TTL_MS = 60 * 60 * 1000;

export interface AppleIdentity {
  sub: string;
  email?: string;
  emailVerified?: boolean;
  nonce: string;
}

export class AppleConfigurationError extends Error {}

@Injectable()
export class AppleProviderService {
  private keys: Map<string, KeyObject> = new Map();
  private keysLoadedAt = 0;

  constructor(private readonly config: ConfigService) {
    const encryptionKey = this.config.get<string>('APPLE_TOKEN_ENCRYPTION_KEY');
    if (encryptionKey && this.encryptionKey().length !== 32) {
      throw new Error('APPLE_TOKEN_ENCRYPTION_KEY must decode to exactly 32 bytes');
    }
  }

  async verifyIdentityToken(token: string, rawNonce: string): Promise<AppleIdentity> {
    const [encodedHeader, encodedClaims, encodedSignature, ...extra] = token.split('.');
    if (!encodedHeader || !encodedClaims || !encodedSignature || extra.length) throw new Error('Invalid Apple identity token');
    const header = parseJson(encodedHeader);
    if (header.alg !== 'RS256' || typeof header.kid !== 'string') throw new Error('Invalid Apple identity token');
    const key = await this.getKey(header.kid);
    const valid = verify('RSA-SHA256', Buffer.from(`${encodedHeader}.${encodedClaims}`), key, Buffer.from(encodedSignature, 'base64url'));
    const claims = parseJson(encodedClaims);
    const audience = this.config.get<string>('APPLE_CLIENT_ID');
    const now = Math.floor(Date.now() / 1000);
    if (!valid || claims.iss !== APPLE_ISSUER || claims.aud !== audience || !audience ||
      typeof claims.sub !== 'string' || !claims.sub || typeof claims.exp !== 'number' || claims.exp <= now ||
      (typeof claims.nbf === 'number' && claims.nbf > now) || claims.nonce !== sha256(rawNonce)) {
      throw new Error('Invalid Apple identity token');
    }
    const email = typeof claims.email === 'string' ? claims.email : undefined;
    return {
      sub: claims.sub,
      ...(email ? { email } : {}),
      ...(claims.email_verified === true || claims.email_verified === 'true' ? { emailVerified: true } : {}),
      nonce: claims.nonce,
    };
  }

  async exchangeAuthorizationCode(code: string, rawNonce: string): Promise<{ identity: AppleIdentity; encryptedRefreshToken: string | null }> {
    const clientId = this.required('APPLE_CLIENT_ID');
    const teamId = this.required('APPLE_TEAM_ID');
    const keyId = this.required('APPLE_KEY_ID');
    const privateKey = this.required('APPLE_PRIVATE_KEY').replace(/\\n/g, '\n');
    const now = Math.floor(Date.now() / 1000);
    const header = base64url(JSON.stringify({ alg: 'ES256', kid: keyId, typ: 'JWT' }));
    const claims = base64url(JSON.stringify({ iss: teamId, iat: now, exp: now + 300, aud: APPLE_ISSUER, sub: clientId }));
    const signer = createSign('SHA256');
    signer.update(`${header}.${claims}`);
    signer.end();
    const clientSecret = `${header}.${claims}.${signer.sign({ key: privateKey, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
    const response = await fetch(APPLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, code, grant_type: 'authorization_code' }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error('Apple authorization code exchange failed');
    const payload: unknown = await response.json();
    if (!isRecord(payload) || typeof payload.id_token !== 'string') throw new Error('Apple authorization response is invalid');
    const identity = await this.verifyIdentityToken(payload.id_token, rawNonce);
    if (typeof payload.refresh_token !== 'string' || !payload.refresh_token) {
      throw new Error('Apple authorization response did not contain a revocable credential');
    }
    return { identity, encryptedRefreshToken: this.encryptRefreshToken(payload.refresh_token) };
  }

  async revokeRefreshToken(encryptedToken: string): Promise<void> {
    const clientId = this.required('APPLE_CLIENT_ID');
    const teamId = this.required('APPLE_TEAM_ID');
    const keyId = this.required('APPLE_KEY_ID');
    const privateKey = this.required('APPLE_PRIVATE_KEY').replace(/\\n/g, '\n');
    const header = base64url(JSON.stringify({ alg: 'ES256', kid: keyId, typ: 'JWT' }));
    const now = Math.floor(Date.now() / 1000);
    const claims = base64url(JSON.stringify({ iss: teamId, iat: now, exp: now + 300, aud: APPLE_ISSUER, sub: clientId }));
    const signer = createSign('SHA256');
    signer.update(`${header}.${claims}`);
    signer.end();
    const clientSecret = `${header}.${claims}.${signer.sign({ key: privateKey, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
    const refreshToken = this.decryptRefreshToken(encryptedToken);
    const response = await fetch(APPLE_TOKEN_URL.replace('/token', '/revoke'), {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, token: refreshToken, token_type_hint: 'refresh_token' }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error('Apple token revocation failed');
  }

  encryptRefreshToken(token: string): string {
    const key = this.encryptionKey();
    if (key.length !== 32) throw new Error('APPLE_TOKEN_ENCRYPTION_KEY must decode to exactly 32 bytes');
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([cipher.update(token, 'utf8'), cipher.final()]);
    return `${iv.toString('base64url')}.${cipher.getAuthTag().toString('base64url')}.${encrypted.toString('base64url')}`;
  }

  private decryptRefreshToken(value: string): string {
    const [iv, tag, ciphertext, ...extra] = value.split('.');
    if (!iv || !tag || !ciphertext || extra.length) throw new Error('Invalid encrypted Apple token');
    const decipher = createDecipheriv('aes-256-gcm', this.encryptionKey(), Buffer.from(iv, 'base64url'));
    decipher.setAuthTag(Buffer.from(tag, 'base64url'));
    return Buffer.concat([decipher.update(Buffer.from(ciphertext, 'base64url')), decipher.final()]).toString('utf8');
  }

  private encryptionKey(): Buffer {
    const encoded = this.config.get<string>('APPLE_TOKEN_ENCRYPTION_KEY');
    if (!encoded) throw new AppleConfigurationError('Apple token encryption is not configured');
    const key = Buffer.from(encoded, 'base64');
    if (key.toString('base64') !== encoded || key.length !== 32) throw new Error('APPLE_TOKEN_ENCRYPTION_KEY must decode to exactly 32 bytes');
    return key;
  }

  private required(name: string): string {
    const value = this.config.get<string>(name)?.trim();
    if (!value) throw new AppleConfigurationError(`Apple authentication is disabled: ${name} is not configured`);
    return value;
  }

  private async getKey(kid: string): Promise<KeyObject> {
    if (Date.now() - this.keysLoadedAt > APPLE_JWKS_TTL_MS || !this.keys.has(kid)) {
      const response = await fetch(APPLE_KEYS_URL, { signal: AbortSignal.timeout(5_000) });
      if (!response.ok) throw new Error('Unable to retrieve Apple signing keys');
      const set: unknown = await response.json();
      if (!isRecord(set) || !Array.isArray(set.keys)) throw new Error('Invalid Apple signing keys');
      const keys = new Map<string, KeyObject>();
      for (const candidate of set.keys) {
        if (isRecord(candidate) && typeof candidate.kid === 'string' && candidate.kty === 'RSA' && candidate.alg === 'RS256' && candidate.use === 'sig' && typeof candidate.n === 'string' && typeof candidate.e === 'string') {
          const jwk: JsonWebKey = { kty: 'RSA', n: candidate.n, e: candidate.e };
          keys.set(candidate.kid, createPublicKey({ key: jwk, format: 'jwk' }));
        }
      }
      this.keys = keys;
      this.keysLoadedAt = Date.now();
    }
    const key = this.keys.get(kid);
    if (!key) throw new Error('Unknown Apple signing key');
    return key;
  }
}

function parseJson(value: string): Record<string, unknown> {
  const parsed: unknown = JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
  if (!isRecord(parsed)) throw new Error('Invalid Apple identity token');
  return parsed;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function base64url(value: string): string { return Buffer.from(value).toString('base64url'); }
function sha256(value: string): string { return createHash('sha256').update(value).digest('hex'); }
