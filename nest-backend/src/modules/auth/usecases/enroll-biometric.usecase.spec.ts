import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { JwtTokenType } from '@/shared/core/types';
import { StepUpService } from '@/shared/auth/step-up.service';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';
import { SessionTokenService } from '../services/session-token.service';
import { EnrollBiometricUseCase } from './enroll-biometric.usecase';

describe('EnrollBiometricUseCase', () => {
  it('registers only the public key after consuming enrollment step-up proof', async () => {
    const credentials = { register: jest.fn().mockResolvedValue(undefined) };
    const stepUp = { consume: jest.fn().mockResolvedValue(true) };
    const tokens = { generateBiometric: jest.fn().mockReturnValue('biometric') };
    const module = await Test.createTestingModule({
      providers: [
        EnrollBiometricUseCase,
        { provide: BiometricCredentialService, useValue: credentials },
        { provide: StepUpService, useValue: stepUp },
        { provide: SessionTokenService, useValue: tokens },
      ],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS, sid: 'family-1', sessionStartedAtMs: 123456789,
    }, 'step-up', 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE');

    expect(result).toMatchObject({ value: { biometricToken: 'biometric' } });
    expect(stepUp.consume).toHaveBeenCalledWith('step-up', 'u1', 'biometric_enroll');
    expect(credentials.register).toHaveBeenCalledWith('u1', 'family-1', 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE');
    expect(tokens.generateBiometric).toHaveBeenCalledWith('u1', UserRole.USER, 'family-1', 123456789);
  });

  it('does not generate or register a credential without consumed step-up proof', async () => {
    const credentials = { register: jest.fn() };
    const stepUp = { consume: jest.fn().mockResolvedValue(false) };
    const tokens = { generateBiometric: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        EnrollBiometricUseCase,
        { provide: BiometricCredentialService, useValue: credentials },
        { provide: StepUpService, useValue: stepUp },
        { provide: SessionTokenService, useValue: tokens },
      ],
    }).compile();

    const result = await module.get(EnrollBiometricUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.ACCESS,
    }, 'invalid-step-up', 'invalid-key');

    expect(result.isLeft()).toBe(true);
    expect(credentials.register).not.toHaveBeenCalled();
    expect(tokens.generateBiometric).not.toHaveBeenCalled();
  });
});
