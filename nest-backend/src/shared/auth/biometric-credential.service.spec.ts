import { StepUpPurpose, BiometricChallengePurpose } from './biometric-credential.service';
import { createPublicKey, generateKeyPairSync, sign, verify } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { BiometricCredentialService } from './biometric-credential.service';

describe('BiometricCredentialService', () => {
  it.each(['padded', 'unpadded'])('accepts a matching one-time P-256 signature (%s) and rejects replay', async (encoding) => {
    const values = new Map<string, string>();
    const redis = {
      get: jest.fn(async (key: string) => values.get(key) ?? null),
      add: jest.fn(async (key: string, value: string) => { values.set(key, value); }),
      setIfAbsent: jest.fn(async (key: string, value: string) => {
        if (values.has(key)) return false;
        values.set(key, value);
        return true;
      }),
    };
    const module = await Test.createTestingModule({
      providers: [BiometricCredentialService, { provide: RedisService, useValue: redis }],
    }).compile();
    const service = module.get(BiometricCredentialService);
    const pair = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const publicKey = pair.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
    const user = { userId: 'u1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-1' };
    await service.register('u1', 'family-1', publicKey);
    const operation = { purpose: BiometricChallengePurpose.STEP_UP as const, stepUpPurpose: StepUpPurpose.CANCEL_ORDER as const, resourceId: 'order-1' };
    const challenge = await service.createChallenge(user, operation);
    if (!challenge) throw new Error('Challenge should be created');
    let signature: string;
    do {
      signature = sign('sha256', Buffer.from(challenge.challenge, 'utf8'), pair.privateKey).toString('base64');
    } while (!signature.endsWith('='));
    if (encoding === 'unpadded') signature = signature.replace(/=+$/, '');
    expect(verify('sha256', Buffer.from(challenge.challenge, 'utf8'), createPublicKey({ key: Buffer.from(publicKey, 'base64'), format: 'der', type: 'spki' }), Buffer.from(signature, 'base64'))).toBe(true);
    expect(await service.verifyAndConsume(user, challenge.challengeId, signature, operation)).toBe(true);
    expect(await service.verifyAndConsume(user, challenge.challengeId, signature, operation)).toBe(false);
  });

  it('rejects signatures for another operation or resource', async () => {
    const values = new Map<string, string>();
    const redis = {
      get: jest.fn(async (key: string) => values.get(key) ?? null),
      add: jest.fn(async (key: string, value: string) => { values.set(key, value); }),
      setIfAbsent: jest.fn(async (key: string, value: string) => { if (values.has(key)) return false; values.set(key, value); return true; }),
    };
    const module = await Test.createTestingModule({ providers: [BiometricCredentialService, { provide: RedisService, useValue: redis }] }).compile();
    const service = module.get(BiometricCredentialService);
    const pair = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const publicKey = pair.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
    const user = { userId: 'u1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-2' };
    await service.register('u1', 'family-2', publicKey);
    const operation = { purpose: BiometricChallengePurpose.STEP_UP as const, stepUpPurpose: StepUpPurpose.CANCEL_ORDER as const, resourceId: 'order-1' };
    const challenge = await service.createChallenge(user, operation);
    if (!challenge) throw new Error('Challenge should be created');
    const signature = sign('sha256', Buffer.from(challenge.challenge), pair.privateKey).toString('base64');

    expect(await service.verifyAndConsume(user, challenge.challengeId, signature, {
      purpose: BiometricChallengePurpose.STEP_UP, stepUpPurpose: StepUpPurpose.CANCEL_ORDER, resourceId: 'order-2',
    })).toBe(false);
  });

  it('removes the bound key when biometric login is disabled', async () => {
    const values = new Map<string, string>();
    const redis = {
      get: jest.fn(async (key: string) => values.get(key) ?? null),
      add: jest.fn(async (key: string, value: string) => { values.set(key, value); }),
      del: jest.fn(async (key: string) => { values.delete(key); }),
      setIfAbsent: jest.fn(),
    };
    const module = await Test.createTestingModule({
      providers: [BiometricCredentialService, { provide: RedisService, useValue: redis }],
    }).compile();
    const service = module.get(BiometricCredentialService);
    const pair = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const publicKey = pair.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
    await service.register('u1', 'family-3', publicKey);

    await service.revoke('family-3');

    expect(await service.createChallenge({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-3',
    }, { purpose: BiometricChallengePurpose.LOGIN })).toBeNull();
  });
});
