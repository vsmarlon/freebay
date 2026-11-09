import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { JwtTokenType } from '@/shared/core/types';
import { StepUpService } from '@/shared/auth/step-up.service';
import { BiometricCredentialService, StepUpPurpose, BiometricChallengePurpose } from '@/shared/auth/biometric-credential.service';
import { SessionTokenService } from '../services/session-token.service';
import { EnrollBiometricUseCase } from './enroll-biometric.usecase';
import { UserDatabaseRepository } from '@/modules/users';
import { generateKeyPairSync, sign } from 'node:crypto';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { AuthUser } from '@/shared/core/types';
import { CreateBiometricEnrollmentChallengeUseCase } from './create-biometric-enrollment-challenge.usecase';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

const ENROLLMENT_TEST_SECRET = 'biometric-enrollment-regression-secret-only';

describe('EnrollBiometricUseCase', () => {
  afterEach(() => jest.restoreAllMocks());

  async function nativeEnrollment(encoding = 'padded', authenticatedAtMs = Date.now()) {
    const values = new Map<string, string>();
    const redis = {
      get: jest.fn(async (key: string) => values.get(key) ?? null),
      add: jest.fn(async (key: string, value: string, _ttl: number) => { values.set(key, value); }),
      setIfAbsent: jest.fn(async (key: string, value: string) => {
        if (values.has(key)) return false;
        values.set(key, value);
        return true;
      }),
    };
    const tokens = { generateBiometric: jest.fn().mockReturnValue('biometric') };
    const users = { update: jest.fn().mockResolvedValue(undefined) };
    const module = await Test.createTestingModule({ imports: [JwtModule.register({ secret: ENROLLMENT_TEST_SECRET })], providers: [
      EnrollBiometricUseCase, CreateBiometricEnrollmentChallengeUseCase, BiometricCredentialService, StepUpService,
      { provide: RedisService, useValue: redis },
      { provide: SessionTokenService, useValue: tokens },
      { provide: UserDatabaseRepository, useValue: users },
      { provide: ConfigService, useValue: { getOrThrow: () => ENROLLMENT_TEST_SECRET } },
    ] }).compile();
    const stepUp = module.get(StepUpService);
    jest.spyOn(stepUp, 'consume');
    const pair = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const publicKey = pair.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
    const user: AuthUser = { userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS, sid: 'family-1', sessionStartedAtMs: 123456789, authenticatedAtMs };
    const result = await module.get(CreateBiometricEnrollmentChallengeUseCase).execute(user, publicKey);
    if (result.isLeft()) throw new Error('Enrollment challenge should be created');
    const challenge = result.value;
    let signature: string;
    do {
      signature = sign('sha256', Buffer.from(challenge.challenge), pair.privateKey).toString('base64');
    } while (!signature.endsWith('='));
    if (encoding === 'unpadded') signature = signature.replace(/=+$/, '');
    return { module, user, publicKey, challenge, signature, redis, values, tokens, stepUp };
  }

  it.each(['padded', 'unpadded'])('enrolls with %s native possession proof once, without password or provider step-up', async (encoding) => {
    const { module, user, publicKey, challenge, signature, redis, stepUp } = await nativeEnrollment(encoding);
    const usecase = module.get(EnrollBiometricUseCase);
    expect((await usecase.execute(user, undefined, publicKey, challenge.challengeId, signature)).isRight()).toBe(true);
    expect((await usecase.execute(user, undefined, publicKey, challenge.challengeId, signature)).isLeft()).toBe(true);
    expect(stepUp.consume).not.toHaveBeenCalled();
    expect(redis.add).toHaveBeenCalledWith(`biometric:enroll-challenge:${challenge.challengeId}`, expect.any(String), 60);
    expect(await module.get(BiometricCredentialService).createChallenge({ ...user, type: JwtTokenType.BIOMETRIC }, { purpose: BiometricChallengePurpose.LOGIN })).not.toBeNull();
    await module.close();
  });

  it.each([
    { label: 'missing', authenticatedAtMs: undefined },
    { label: 'zero', authenticatedAtMs: 0 },
    { label: 'negative', authenticatedAtMs: -1 },
    { label: 'fractional', authenticatedAtMs: 1_800_000_000_000 - 0.5 },
    { label: 'unsafe', authenticatedAtMs: Number.MAX_SAFE_INTEGER + 1 },
    { label: 'future', authenticatedAtMs: 1_800_000_000_001 },
    { label: 'stale', authenticatedAtMs: 1_800_000_000_000 - 300_001 },
  ])('rejects $label authentication evidence at challenge creation and consumption', async ({ authenticatedAtMs }) => {
    jest.spyOn(Date, 'now').mockReturnValue(1_800_000_000_000);
    const { module, user, publicKey, challenge, signature, tokens, values } = await nativeEnrollment();
    const invalidUser = { ...user, authenticatedAtMs, issuedAtMs: Date.now() };
    const created = await module.get(CreateBiometricEnrollmentChallengeUseCase).execute(invalidUser, publicKey);
    expect(created.isLeft()).toBe(true);
    const consumed = await module.get(EnrollBiometricUseCase).execute(invalidUser, undefined, publicKey, challenge.challengeId, signature);
    expect(consumed.isLeft()).toBe(true);
    expect(tokens.generateBiometric).not.toHaveBeenCalled();
    expect(values.has(`biometric:enroll-consumed:${challenge.challengeId}`)).toBe(false);
    expect(values.has('biometric:key:family-1')).toBe(false);
    await module.close();
  });

  it('accepts authentication exactly five minutes old at challenge creation and consumption', async () => {
    jest.spyOn(Date, 'now').mockReturnValue(1_800_000_000_000);
    const { module, user, publicKey, challenge, signature } = await nativeEnrollment('unpadded', Date.now() - 300_000);
    expect((await module.get(EnrollBiometricUseCase).execute(user, undefined, publicKey, challenge.challengeId, signature)).isRight()).toBe(true);
    await module.close();
  });

  it('rejects a proof crossing the five-minute boundary during the native prompt while allowing a valid legacy step-up', async () => {
    const clock = jest.spyOn(Date, 'now').mockReturnValue(1_800_000_000_000);
    const { module, user, publicKey, challenge, signature, tokens, stepUp } = await nativeEnrollment('unpadded', Date.now() - 299_999);
    clock.mockReturnValue(1_800_000_000_002);
    const usecase = module.get(EnrollBiometricUseCase);
    expect((await usecase.execute(user, undefined, publicKey, challenge.challengeId, signature)).isLeft()).toBe(true);
    expect(tokens.generateBiometric).not.toHaveBeenCalled();
    const proof = await stepUp.issue(user.userId, StepUpPurpose.BIOMETRIC_ENROLL);
    expect((await usecase.execute(user, proof.stepUpToken, publicKey)).isRight()).toBe(true);
    expect((await usecase.execute(user, proof.stepUpToken, publicKey)).isLeft()).toBe(true);
    await module.close();
  });

  it.each(['owner', 'sid', 'origin', 'key', 'signature', 'signature-substitution', 'expired', 'missing-sid', 'missing-origin', 'biometric-token'])(
    'rejects mismatched or absent enrollment evidence: %s', async (failure) => {
      const fixture = await nativeEnrollment();
      const { module, challenge, values, tokens } = fixture;
      let { user, publicKey, signature } = fixture;
      if (failure === 'owner') user = { ...user, userId: 'u2' };
      if (failure === 'sid') user = { ...user, sid: 'other-family' };
      if (failure === 'origin') user = { ...user, sessionStartedAtMs: 987654321 };
      if (failure === 'key') publicKey = generateKeyPairSync('ec', { namedCurve: 'prime256v1' }).publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
      if (failure === 'signature') signature = '';
      if (failure === 'signature-substitution') signature = sign('sha256', Buffer.from(challenge.challenge), generateKeyPairSync('ec', { namedCurve: 'prime256v1' }).privateKey).toString('base64');
      if (failure === 'expired') values.delete(`biometric:enroll-challenge:${challenge.challengeId}`);
      if (failure === 'missing-sid') user = { ...user, sid: undefined };
      if (failure === 'missing-origin') user = { ...user, sessionStartedAtMs: undefined };
      if (failure === 'biometric-token') user = { ...user, type: JwtTokenType.BIOMETRIC };
      expect((await module.get(EnrollBiometricUseCase).execute(user, undefined, publicKey, challenge.challengeId, signature)).isLeft()).toBe(true);
      expect(tokens.generateBiometric).not.toHaveBeenCalled();
      expect(values.has('biometric:key:family-1')).toBe(false);
      await module.close();
    },
  );

  it('registers only the public key after consuming enrollment step-up proof', async () => {
    const credentials = { register: jest.fn().mockResolvedValue(undefined) };
    const stepUp = { consume: jest.fn().mockResolvedValue(true) };
    const tokens = { generateBiometric: jest.fn().mockReturnValue('biometric') };
    const users = { update: jest.fn().mockResolvedValue(undefined) };
    const module = await Test.createTestingModule({
      providers: [
        EnrollBiometricUseCase,
        { provide: BiometricCredentialService, useValue: credentials },
        { provide: StepUpService, useValue: stepUp },
        { provide: SessionTokenService, useValue: tokens },
        { provide: UserDatabaseRepository, useValue: users },
      ],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS, sid: 'family-1', sessionStartedAtMs: 123456789,
    }, 'step-up', 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE');

    expect(result).toMatchObject({ value: { biometricToken: 'biometric' } });
    expect(stepUp.consume).toHaveBeenCalledWith('step-up', 'u1', StepUpPurpose.BIOMETRIC_ENROLL);
    expect(credentials.register).toHaveBeenCalledWith('u1', 'family-1', 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE');
    expect(tokens.generateBiometric).toHaveBeenCalledWith('u1', UserRole.USER, 'family-1', 123456789);
    expect(users.update).toHaveBeenCalledWith('u1', { biometryLoginEnabled: true });
  });

  it('does not generate or register a credential without consumed step-up proof', async () => {
    const credentials = { register: jest.fn() };
    const stepUp = { consume: jest.fn().mockResolvedValue(false) };
    const tokens = { generateBiometric: jest.fn() };
    const users = { update: jest.fn().mockResolvedValue(undefined) };
    const module = await Test.createTestingModule({
      providers: [
        EnrollBiometricUseCase,
        { provide: BiometricCredentialService, useValue: credentials },
        { provide: StepUpService, useValue: stepUp },
        { provide: SessionTokenService, useValue: tokens },
        { provide: UserDatabaseRepository, useValue: users },
      ],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS,
    }, 'invalid-step-up', 'invalid-key');

    expect(result.isLeft()).toBe(true);
    expect(credentials.register).not.toHaveBeenCalled();
    expect(tokens.generateBiometric).not.toHaveBeenCalled();
    expect(users.update).not.toHaveBeenCalled();
  });
});
