import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';
import { UserDatabaseRepository } from '@/modules/users';
import { SessionTokenService } from '../services/session-token.service';
import { BiometricLoginUseCase } from './biometric-login.usecase';

describe('BiometricLoginUseCase', () => {
  const payload = {
    userId: 'u1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-1', jti: 'bio-1',
    exp: Math.floor(Date.now() / 1000) + 60,
    sessionStartedAtMs: 123456789,
  };

  async function createSubject(proofValid = true, claimed = true) {
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: UserRole.USER, suspendedAt: null })) };
    const validator = { verifyAndValidate: jest.fn().mockResolvedValue(payload) };
    const credentials = { verifyAndConsume: jest.fn().mockResolvedValue(proofValid) };
    const tokens = {
      claimBiometric: jest.fn().mockResolvedValue(claimed),
      generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }),
      generateBiometric: jest.fn().mockReturnValue('rotated-biometric'),
    };
    const module = await Test.createTestingModule({
      providers: [
        BiometricLoginUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: JwtTokenValidatorService, useValue: validator },
        { provide: BiometricCredentialService, useValue: credentials },
        { provide: SessionTokenService, useValue: tokens },
      ],
    }).compile();
    return { sut: module.get(BiometricLoginUseCase), credentials, tokens, validator };
  }

  const body = { biometricToken: 'bound-token', challengeId: 'challenge-id', signature: 'c2ln' };

  it('requires a one-time key signature and keeps the original family without inventing fresh auth time', async () => {
    const { sut, credentials, tokens, validator } = await createSubject();

    const result = await sut.execute(body);

    expect(result.isRight()).toBe(true);
    expect(validator.verifyAndValidate).toHaveBeenCalledWith('bound-token', [JwtTokenType.BIOMETRIC]);
    expect(credentials.verifyAndConsume).toHaveBeenCalledWith(payload, 'challenge-id', 'c2ln', { purpose: 'login' });
    expect(tokens.generate).toHaveBeenCalledWith('u1', UserRole.USER, null, 'family-1', 123456789);
    expect(tokens.generateBiometric).toHaveBeenCalledWith('u1', UserRole.USER, 'family-1', 123456789);
  });

  it('rejects legacy bearer tokens without a registered-key signature', async () => {
    const { sut, tokens } = await createSubject(false);

    const result = await sut.execute(body);

    expect(result.isLeft()).toBe(true);
    expect(tokens.claimBiometric).not.toHaveBeenCalled();
  });

  it('rejects reuse after revoking the entire session family', async () => {
    const { sut, tokens } = await createSubject(true, false);

    const result = await sut.execute(body);

    expect(result.isLeft()).toBe(true);
    expect(tokens.claimBiometric).toHaveBeenCalledWith('bio-1', payload.exp, 'family-1');
  });
});
