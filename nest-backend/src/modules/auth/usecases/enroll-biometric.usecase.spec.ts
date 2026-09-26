import { Test } from '@nestjs/testing';
import { JwtTokenType } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { EnrollBiometricUseCase } from './enroll-biometric.usecase';
import { UserRole } from '@prisma/client';

describe('EnrollBiometricUseCase', () => {
  it('allows one recent access-token enrollment', async () => {
    const tokens = {
      claimBiometricEnrollment: jest.fn().mockResolvedValue(true),
      generateBiometric: jest.fn().mockReturnValue('biometric'),
    };
    const module = await Test.createTestingModule({
      providers: [EnrollBiometricUseCase, { provide: SessionTokenService, useValue: tokens }],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS, jti: 'j1', iat: Math.floor(Date.now() / 1000),
    });

    expect(result).toMatchObject({ value: { biometricToken: 'biometric' } });
  });

  it('rejects a stale access token before claiming enrollment', async () => {
    const tokens = { claimBiometricEnrollment: jest.fn(), generateBiometric: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [EnrollBiometricUseCase, { provide: SessionTokenService, useValue: tokens }],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS, jti: 'j1', iat: Math.floor(Date.now() / 1000) - 301,
    });

    expect(result.isLeft()).toBe(true);
    expect(tokens.claimBiometricEnrollment).not.toHaveBeenCalled();
  });
});
