import { createHash, createPublicKey, randomBytes, randomUUID, verify } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';

export const BIOMETRIC_CREDENTIAL_TTL_SECONDS = 30 * 24 * 60 * 60;
export enum StepUpPurpose {
  BIOMETRIC_ENROLL = 'biometric_enroll',
  DELETE_ACCOUNT = 'delete_account',
  EXPORT_DATA = 'export_data',
  CONNECT_DASHBOARD = 'connect_dashboard',
  CANCEL_ORDER = 'cancel_order',
}

export enum BiometricChallengePurpose {
  LOGIN = 'login',
  STEP_UP = 'step_up',
}

export type BiometricOperation =
  | { purpose: BiometricChallengePurpose.LOGIN }
  | { purpose: BiometricChallengePurpose.STEP_UP; stepUpPurpose: StepUpPurpose; resourceId?: string };

type KeyBinding = { userId: string; credentialId: string; publicKey: string; thumbprint: string };
type Challenge = KeyBinding & { sid: string; challenge: string; operation: BiometricOperation };
type EnrollmentChallenge = { userId: string; sid: string; sessionStartedAtMs: number; thumbprint: string; challenge: string };

export class InvalidBiometricPublicKeyError extends Error {}

@Injectable()
export class BiometricCredentialService {
  constructor(private readonly redis: RedisService) {}

  async register(userId: string, sid: string, encodedPublicKey: string): Promise<void> {
    const publicKey = this.decodePublicKey(encodedPublicKey);
    const binding: KeyBinding = {
      userId,
      credentialId: randomUUID(),
      publicKey: encodedPublicKey,
      thumbprint: createHash('sha256').update(publicKey).digest('hex'),
    };
    await this.redis.add(this.bindingKey(sid), JSON.stringify(binding), BIOMETRIC_CREDENTIAL_TTL_SECONDS);
  }

  async revoke(sid: string): Promise<void> {
    await this.redis.del(this.bindingKey(sid));
  }

  async createEnrollmentChallenge(user: AuthUser, publicKey: string): Promise<{ challengeId: string; challenge: string } | null> {
    if (!isEnrollmentSession(user) || !hasRecentEnrollmentAuthentication(user)) return null;
    const thumbprint = createHash('sha256').update(this.decodePublicKey(publicKey)).digest('hex');
    const challengeId = randomUUID();
    const challenge = `freebay:v1:biometric_enroll:${randomBytes(32).toString('base64url')}`;
    const entry: EnrollmentChallenge = {
      userId: user.userId, sid: user.sid, sessionStartedAtMs: user.sessionStartedAtMs, thumbprint, challenge,
    };
    await this.redis.add(`biometric:enroll-challenge:${challengeId}`, JSON.stringify(entry), 60);
    return { challengeId, challenge };
  }

  async verifyEnrollmentAndConsume(user: AuthUser, publicKey: string, challengeId: string, signature: string): Promise<boolean> {
    if (!isEnrollmentSession(user) || !hasRecentEnrollmentAuthentication(user) || !isBase64(signature)) return false;
    const raw = await this.redis.get(`biometric:enroll-challenge:${challengeId}`);
    if (!raw) return false;
    try {
      const entry: unknown = JSON.parse(raw);
      const der = this.decodePublicKey(publicKey);
      if (!isRecord(entry) || entry.userId !== user.userId || entry.sid !== user.sid ||
        entry.sessionStartedAtMs !== user.sessionStartedAtMs || typeof entry.challenge !== 'string' ||
        entry.thumbprint !== createHash('sha256').update(der).digest('hex')) return false;
      const key = createPublicKey({ key: der, format: 'der', type: 'spki' });
      if (!verify('sha256', Buffer.from(entry.challenge, 'utf8'), key, Buffer.from(signature, 'base64'))) return false;
      return this.redis.setIfAbsent(`biometric:enroll-consumed:${challengeId}`, '1', 60);
    } catch {
      return false;
    }
  }

  async createChallenge(user: AuthUser, operation: BiometricOperation): Promise<{ challengeId: string; challenge: string } | null> {
    if (user.type !== JwtTokenType.BIOMETRIC || !user.userId || !user.sid) return null;
    const raw = await this.redis.get(this.bindingKey(user.sid));
    if (!raw) return null;
    const binding = this.parseBinding(raw);
    if (!binding || binding.userId !== user.userId) return null;
    const challengeId = randomUUID();
    const resource = operation.purpose === BiometricChallengePurpose.STEP_UP ? operation.resourceId ?? '-' : '-';
    const challenge = `freebay:v1:${operation.purpose}:${operation.purpose === BiometricChallengePurpose.STEP_UP ? operation.stepUpPurpose : BiometricChallengePurpose.LOGIN}:${resource}:${randomBytes(32).toString('base64url')}`;
    const entry: Challenge = { ...binding, sid: user.sid, challenge, operation };
    await this.redis.add(`biometric:challenge:${challengeId}`, JSON.stringify(entry), 60);
    await this.redis.add(this.bindingKey(user.sid), JSON.stringify(binding), BIOMETRIC_CREDENTIAL_TTL_SECONDS);
    return { challengeId, challenge };
  }

  async verifyAndConsume(user: AuthUser, challengeId: string, signature: string, operation: BiometricOperation): Promise<boolean> {
    if (user.type !== JwtTokenType.BIOMETRIC || !user.userId || !user.sid || !isBase64(signature)) return false;
    const key = `biometric:challenge:${challengeId}`;
    const raw = await this.redis.get(key);
    if (!raw) return false;
    const entry = parseChallenge(raw);
    if (!entry || entry.userId !== user.userId || entry.sid !== user.sid || !sameOperation(entry.operation, operation)) return false;
    const activeRaw = await this.redis.get(this.bindingKey(user.sid));
    const active = activeRaw ? this.parseBinding(activeRaw) : null;
    if (!active || active.userId !== user.userId || active.thumbprint !== entry.thumbprint) return false;
    const publicKey = createPublicKey({ key: this.decodePublicKey(entry.publicKey), format: 'der', type: 'spki' });
    try {
      if (!verify('sha256', Buffer.from(entry.challenge, 'utf8'), publicKey, Buffer.from(signature, 'base64'))) return false;
    } catch {
      return false;
    }
    return this.redis.setIfAbsent(`biometric:challenge-consumed:${challengeId}`, '1', 60);
  }

  private decodePublicKey(value: string) {
    try {
      if (!isBase64(value)) throw new Error('Invalid biometric public key encoding');
      const der = Buffer.from(value, 'base64');
      const key = createPublicKey({ key: der, format: 'der', type: 'spki' });
      if (key.asymmetricKeyType !== 'ec' || key.asymmetricKeyDetails?.namedCurve !== 'prime256v1') {
        throw new Error('Biometric key must be P-256');
      }
      return der;
    } catch {
      throw new InvalidBiometricPublicKeyError();
    }
  }

  private parseBinding(value: string): KeyBinding | null {
    try {
      const parsed: unknown = JSON.parse(value);
      if (!isKeyBinding(parsed)) return null;
      this.decodePublicKey(parsed.publicKey);
      return parsed;
    } catch {
      return null;
    }
  }

  private bindingKey(sid: string) { return `biometric:key:${sid}`; }
}

function parseChallenge(value: string): Challenge | null {
  try {
    const parsed: unknown = JSON.parse(value);
    return isChallenge(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function isKeyBinding(value: unknown): value is KeyBinding {
  if (!isRecord(value)) return false;
  const item = value;
  return typeof item.userId === 'string' && typeof item.credentialId === 'string' &&
    typeof item.publicKey === 'string' && typeof item.thumbprint === 'string';
}

function isChallenge(value: unknown): value is Challenge {
  if (!isRecord(value)) return false;
  const item = value;
  return typeof item.userId === 'string' && typeof item.credentialId === 'string' &&
    typeof item.publicKey === 'string' && typeof item.thumbprint === 'string' &&
    typeof item.sid === 'string' && typeof item.challenge === 'string' && isOperation(item.operation);
}

function isOperation(value: unknown): value is BiometricOperation {
  if (!isRecord(value)) return false;
  const item = value;
  if (item.purpose === BiometricChallengePurpose.LOGIN) return true;
  return item.purpose === BiometricChallengePurpose.STEP_UP && isStepUpPurpose(item.stepUpPurpose) &&
    (item.resourceId === undefined || typeof item.resourceId === 'string');
}

function sameOperation(left: BiometricOperation, right: BiometricOperation): boolean {
  if (left.purpose !== right.purpose) return false;
  return left.purpose === BiometricChallengePurpose.LOGIN || (right.purpose === BiometricChallengePurpose.STEP_UP &&
    left.stepUpPurpose === right.stepUpPurpose && left.resourceId === right.resourceId);
}

export function isStepUpPurpose(value: unknown): value is StepUpPurpose {
  if (typeof value !== 'string') return false;
  switch (value) {
    case StepUpPurpose.BIOMETRIC_ENROLL:
    case StepUpPurpose.DELETE_ACCOUNT:
    case StepUpPurpose.EXPORT_DATA:
    case StepUpPurpose.CONNECT_DASHBOARD:
    case StepUpPurpose.CANCEL_ORDER:
      return true;
    default:
      return false;
  }
}

function isBase64(value: string): boolean {
  return value.length > 0 && /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}(?:==)?|[A-Za-z0-9+/]{3}=?)?$/.test(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function hasRecentEnrollmentAuthentication(user: AuthUser): boolean {
  const authenticatedAtMs = user.authenticatedAtMs;
  const now = Date.now();
  return typeof authenticatedAtMs === 'number' && Number.isSafeInteger(authenticatedAtMs) && authenticatedAtMs > 0 &&
    authenticatedAtMs <= now && now - authenticatedAtMs <= 5 * 60 * 1000;
}

export function isEnrollmentSession(user: AuthUser): user is AuthUser & { sid: string; sessionStartedAtMs: number } {
  return user.type === JwtTokenType.ACCESS && !!user.userId && !!user.sid &&
    typeof user.sessionStartedAtMs === 'number' && Number.isSafeInteger(user.sessionStartedAtMs) && user.sessionStartedAtMs > 0;
}
