import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'node:crypto';
import { UserRole } from '@prisma/client';
import { right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { StepUpService } from '@/shared/auth/step-up.service';
import { BiometricCredentialService, StepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { AppleProviderService } from '@/shared/auth/apple-provider.service';
import { UserDatabaseRepository } from '@/modules/users';
import { GoogleAuthUseCase } from './google-auth.usecase';
import { CreateStepUpUseCase } from './create-step-up.usecase';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { signStepUpMagicContext } from '../utils/step-up-magic-context';

describe('CreateStepUpUseCase provider proof', () => {
  const user = { userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS };

  it('accepts only a recently verified Google subject linked to the authenticated user', async () => {
    const users = { findByGoogleId: jest.fn().mockResolvedValue(right({ id: 'user-1' })) };
    const google = { verifyForStepUp: jest.fn().mockResolvedValue({ subject: 'google-sub' }) };
    const stepUp = { issue: jest.fn().mockResolvedValue({ stepUpToken: 'token', expiresAt: new Date().toISOString() }) };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: GoogleAuthUseCase, useValue: google },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn((key: string) => key === 'JWT_SECRET' ? 'test-secret' : 'web-service-id') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.EXPORT_DATA, proof: { kind: 'google', idToken: 'verified-token' },
    });

    expect(result.isRight()).toBe(true);
    expect(users.findByGoogleId).toHaveBeenCalledWith('google-sub');
    expect(stepUp.issue).toHaveBeenCalledWith('user-1', StepUpPurpose.EXPORT_DATA, undefined);
  });

  it('rejects stale/unlinked Google proof without email-based account matching', async () => {
    const users = { findByGoogleId: jest.fn().mockResolvedValue(right({ id: 'other-user' })), findByEmail: jest.fn() };
    const google = { verifyForStepUp: jest.fn().mockResolvedValue(null) };
    const stepUp = { issue: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: GoogleAuthUseCase, useValue: google },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn((key: string) => key === 'JWT_SECRET' ? 'test-secret' : 'web-service-id') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.DELETE_ACCOUNT, proof: { kind: 'google', idToken: 'stale-token' },
    });

    expect(result.isLeft()).toBe(true);
    expect(users.findByGoogleId).not.toHaveBeenCalled();
    expect(users.findByEmail).not.toHaveBeenCalled();
    expect(stepUp.issue).not.toHaveBeenCalled();
  });

  it('rejects resources for unrelated purposes and requires an order for cancellation', async () => {
    const google = { verifyForStepUp: jest.fn() };
    const stepUp = { issue: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: GoogleAuthUseCase, useValue: google },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn((key: string) => key === 'JWT_SECRET' ? 'test-secret' : 'web-service-id') } },
      ],
    }).compile();
    const sut = module.get(CreateStepUpUseCase);

    const unrelatedResource = await sut.execute(user, {
      purpose: StepUpPurpose.EXPORT_DATA, resourceId: '550e8400-e29b-41d4-a716-446655440000', proof: { kind: 'password', password: 'x' },
    });
    const missingResource = await sut.execute(user, {
      purpose: StepUpPurpose.CANCEL_ORDER, proof: { kind: 'password', password: 'x' },
    });

    expect(unrelatedResource.isLeft()).toBe(true);
    expect(missingResource.isLeft()).toBe(true);
    expect(google.verifyForStepUp).not.toHaveBeenCalled();
    expect(stepUp.issue).not.toHaveBeenCalled();
  });

  it('requires cancellation resource identifiers to be UUIDs before accepting any proof', async () => {
    const google = { verifyForStepUp: jest.fn().mockResolvedValue({ subject: 'google-sub' }) };
    const stepUp = { issue: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: { findByGoogleId: jest.fn().mockResolvedValue(right({ id: 'user-1' })) } },
        { provide: GoogleAuthUseCase, useValue: google },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn((key: string) => key === 'JWT_SECRET' ? 'test-secret' : 'web-service-id') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.CANCEL_ORDER, resourceId: 'order-123', proof: { kind: 'google', idToken: 'fresh-token' },
    });

    expect(result.isLeft()).toBe(true);
    expect(google.verifyForStepUp).not.toHaveBeenCalled();
    expect(stepUp.issue).not.toHaveBeenCalled();
  });

  it('consumes an HMAC-bound email proof for the current web user and exact action/resource', async () => {
    const rawToken = `stepup.${'r'.repeat(43)}`;
    const tokenHash = createHash('sha256').update(rawToken).digest('hex');
    const resourceId = '550e8400-e29b-41d4-a716-446655440000';
    const contextSignature = signStepUpMagicContext('test-secret', { userId: 'user-1', purpose: StepUpPurpose.CANCEL_ORDER, resourceId, tokenHash });
    const magicLinks = { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) };
    const stepUp = { issue: jest.fn().mockResolvedValue({ stepUpToken: 'issued-step-up', expiresAt: new Date().toISOString() }) };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: GoogleAuthUseCase, useValue: {} },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: magicLinks },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn(() => 'test-secret') } },
      ],
    }).compile();
    const webUser = { ...user, sessionStartedAtMs: 1_700_000_000_000 };

    const result = await module.get(CreateStepUpUseCase).execute(webUser, {
      purpose: StepUpPurpose.CANCEL_ORDER, resourceId,
      proof: { kind: 'magic_link', token: rawToken, contextSignature },
    }, { web: true });

    expect(result.isRight()).toBe(true);
    expect(magicLinks.consumeStepUpProof).toHaveBeenCalledWith(tokenHash, 'user-1', webUser.sessionStartedAtMs, expect.any(Date));
    expect(stepUp.issue).toHaveBeenCalledWith('user-1', StepUpPurpose.CANCEL_ORDER, resourceId);
  });

  it.each([
    ['another user', 'user-2', StepUpPurpose.CANCEL_ORDER, '550e8400-e29b-41d4-a716-446655440000'],
    ['another purpose', 'user-1', StepUpPurpose.DELETE_ACCOUNT, undefined],
    ['another resource', 'user-1', StepUpPurpose.CANCEL_ORDER, '550e8400-e29b-41d4-a716-446655440001'],
  ] as const)('does not consume an email proof bound to %s', async (_label, userId, purpose, resourceId) => {
    const rawToken = `stepup.${'x'.repeat(43)}`;
    const tokenHash = createHash('sha256').update(rawToken).digest('hex');
    const originalResource = '550e8400-e29b-41d4-a716-446655440000';
    const contextSignature = signStepUpMagicContext('test-secret', {
      userId: 'user-1', purpose: StepUpPurpose.CANCEL_ORDER, resourceId: originalResource, tokenHash,
    });
    const magicLinks = { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) };
    const stepUp = { issue: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: GoogleAuthUseCase, useValue: {} },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: magicLinks },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn(() => 'test-secret') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute({ ...user, userId, sessionStartedAtMs: 1_700_000_000_000 }, {
      purpose, ...(resourceId ? { resourceId } : {}),
      proof: { kind: 'magic_link', token: rawToken, contextSignature },
    }, { web: true });

    expect(result.isLeft()).toBe(true);
    expect(magicLinks.consumeStepUpProof).not.toHaveBeenCalled();
    expect(stepUp.issue).not.toHaveBeenCalled();
  });

  it('rejects email proof outside web step-up and rejects non-step-up prefixes in web mode', async () => {
    const magicLinks = { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) };
    const stepUp = { issue: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: GoogleAuthUseCase, useValue: {} },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: {} },
        { provide: MagicLinkRepository, useValue: magicLinks },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn(() => 'test-secret') } },
      ],
    }).compile();
    const contextSignature = signStepUpMagicContext('test-secret', {
      userId: 'user-1', purpose: StepUpPurpose.EXPORT_DATA, tokenHash: '00'.repeat(32),
    });

    const native = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.EXPORT_DATA, proof: { kind: 'magic_link', token: `stepup.${'a'.repeat(43)}`, contextSignature },
    });
    const wrongPrefix = await module.get(CreateStepUpUseCase).execute({ ...user, sessionStartedAtMs: 1_700_000_000_000 }, {
      purpose: StepUpPurpose.EXPORT_DATA, proof: { kind: 'magic_link', token: `delete.${'a'.repeat(43)}`, contextSignature },
    }, { web: true });

    expect(native.isLeft()).toBe(true);
    expect(wrongPrefix.isLeft()).toBe(true);
    expect(magicLinks.consumeStepUpProof).not.toHaveBeenCalled();
    expect(stepUp.issue).not.toHaveBeenCalled();
  });

  it('requires a recent nonce-validated Apple subject linked to the same user', async () => {
    const now = Math.floor(Date.now() / 1000);
    const identityToken = `header.${Buffer.from(JSON.stringify({ iat: now })).toString('base64url')}.signature`;
    const users = { findByAppleId: jest.fn().mockResolvedValue(right({ id: 'user-1' })) };
    const apple = { verifyIdentityToken: jest.fn().mockResolvedValue({ sub: 'apple-sub' }) };
    const stepUp = { issue: jest.fn().mockResolvedValue({ stepUpToken: 'token', expiresAt: new Date().toISOString() }) };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: GoogleAuthUseCase, useValue: {} },
        { provide: StepUpService, useValue: stepUp },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: apple },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn().mockResolvedValue(right(true)) } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn((key: string) => key === 'JWT_SECRET' ? 'test-secret' : 'web-service-id') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.DELETE_ACCOUNT,
      proof: { kind: 'apple', identityToken, rawNonce: 'nonce-that-was-validated' },
    });

    expect(result.isRight()).toBe(true);
    expect(apple.verifyIdentityToken).toHaveBeenCalledWith(identityToken, 'nonce-that-was-validated');
    expect(users.findByAppleId).toHaveBeenCalledWith('apple-sub');
    expect(stepUp.issue).toHaveBeenCalledWith('user-1', StepUpPurpose.DELETE_ACCOUNT, undefined);
  });

  it('validates web Apple step-up against the server-configured Services ID', async () => {
    const now = Math.floor(Date.now() / 1000);
    const identityToken = `header.${Buffer.from(JSON.stringify({ iat: now })).toString('base64url')}.signature`;
    const apple = { verifyIdentityToken: jest.fn().mockResolvedValue({ sub: 'apple-sub' }) };
    const users = { findByAppleId: jest.fn().mockResolvedValue(right({ id: 'user-1' })) };
    const module = await Test.createTestingModule({
      providers: [
        CreateStepUpUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: GoogleAuthUseCase, useValue: {} },
        { provide: StepUpService, useValue: { issue: jest.fn().mockResolvedValue({ stepUpToken: 'token', expiresAt: new Date().toISOString() }) } },
        { provide: BiometricCredentialService, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: AppleProviderService, useValue: apple },
        { provide: MagicLinkRepository, useValue: { consumeStepUpProof: jest.fn() } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn(() => 'com.example.web-service') } },
      ],
    }).compile();

    const result = await module.get(CreateStepUpUseCase).execute(user, {
      purpose: StepUpPurpose.EXPORT_DATA, proof: { kind: 'apple', identityToken, rawNonce: 'raw-nonce' },
    }, { web: true });

    expect(result.isRight()).toBe(true);
    expect(apple.verifyIdentityToken).toHaveBeenCalledWith(identityToken, 'raw-nonce', 'com.example.web-service');
    expect(users.findByAppleId).toHaveBeenCalledWith('apple-sub');
  });
});
