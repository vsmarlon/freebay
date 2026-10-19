import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';
import { CreateBiometricChallengeUseCase } from './create-biometric-challenge.usecase';

describe('CreateBiometricChallengeUseCase', () => {
  it('requires the exact step-up purpose and resource shape before issuing a challenge', async () => {
    const credentials = { createChallenge: jest.fn().mockResolvedValue({ challengeId: 'challenge', challenge: 'value' }) };
    const validator = { verifyAndValidate: jest.fn().mockResolvedValue({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-1',
    }) };
    const module = await Test.createTestingModule({
      providers: [
        CreateBiometricChallengeUseCase,
        { provide: JwtTokenValidatorService, useValue: validator },
        { provide: BiometricCredentialService, useValue: credentials },
      ],
    }).compile();
    const sut = module.get(CreateBiometricChallengeUseCase);

    const noPurpose = await sut.execute({ biometricToken: 'token', purpose: 'step_up' });
    const extraOnLogin = await sut.execute({ biometricToken: 'token', purpose: 'login', stepUpPurpose: 'export_data' });
    const missingOrder = await sut.execute({ biometricToken: 'token', purpose: 'step_up', stepUpPurpose: 'cancel_order' });
    const extraResource = await sut.execute({ biometricToken: 'token', purpose: 'step_up', stepUpPurpose: 'export_data', resourceId: 'order-1' });

    expect([noPurpose, extraOnLogin, missingOrder, extraResource].every((result) => result.isLeft())).toBe(true);
    expect(credentials.createChallenge).not.toHaveBeenCalled();
  });

  it('binds a valid cancel-order challenge to the requested order', async () => {
    const credentials = { createChallenge: jest.fn().mockResolvedValue({ challengeId: 'challenge', challenge: 'value' }) };
    const validator = { verifyAndValidate: jest.fn().mockResolvedValue({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.BIOMETRIC, sid: 'family-1',
    }) };
    const module = await Test.createTestingModule({
      providers: [
        CreateBiometricChallengeUseCase,
        { provide: JwtTokenValidatorService, useValue: validator },
        { provide: BiometricCredentialService, useValue: credentials },
      ],
    }).compile();

    const result = await module.get(CreateBiometricChallengeUseCase).execute({
      biometricToken: 'token', purpose: 'step_up', stepUpPurpose: 'cancel_order', resourceId: '550e8400-e29b-41d4-a716-446655440000',
    });

    expect(result.isRight()).toBe(true);
    expect(credentials.createChallenge).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-1' }), {
      purpose: 'step_up', stepUpPurpose: 'cancel_order', resourceId: '550e8400-e29b-41d4-a716-446655440000',
    });
  });
});
