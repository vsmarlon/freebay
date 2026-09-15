import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { JwtTokenType } from '@/shared/core/types';
import { UserDatabaseRepository } from './data/repositories/user-database.repository';
import { SessionTokenService } from './services/session-token.service';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { CheckUsernameAvailabilityUseCase } from './usecases/check-username-availability.usecase';
import { BiometricLoginUseCase } from './usecases/biometric-login.usecase';
import { GoogleAuthUseCase } from './usecases/google-auth.usecase';
import { CompleteProfileUseCase } from './usecases/complete-profile.usecase';
import { RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
import { AuthService } from './auth.service';

describe('AuthService biometric enrollment', () => {
  const createSubject = async (session: object) => {
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: SessionTokenService, useValue: session },
        ...[
          RegisterUseCase,
          LoginUseCase,
          RequestPasswordRecoveryUseCase,
          VerifyPasswordRecoveryCodeUseCase,
          ResetPasswordUseCase,
          CheckUsernameAvailabilityUseCase,
          BiometricLoginUseCase,
          GoogleAuthUseCase,
          CompleteProfileUseCase,
          RequestMagicLinkUseCase,
          ConsumeMagicLinkUseCase,
          RefreshWebSessionUseCase,
          LogoutWebSessionUseCase,
        ].map((token) => ({ provide: token, useValue: {} })),
        { provide: JwtService, useValue: {} },
      ],
    }).compile();
    return module.get(AuthService);
  };

  const user = {
    userId: 'u1',
    role: 'USER',
    type: JwtTokenType.ACCESS,
    jti: 'access-jti',
    iat: Math.floor(Date.now() / 1000),
  };

  it('allows enrollment with a fresh access token', async () => {
    const session = {
      claimBiometricEnrollment: jest.fn().mockResolvedValue(true),
      generateBiometric: jest.fn().mockReturnValue('biometric-token'),
    };
    const result = await (await createSubject(session)).enrollBiometricToken(user);

    expect(result).toEqual({ biometricToken: 'biometric-token' });
  });

  it('rejects enrollment with a stale access token', async () => {
    const session = {
      claimBiometricEnrollment: jest.fn(),
      generateBiometric: jest.fn(),
    };
    const result = await (await createSubject(session)).enrollBiometricToken({
      ...user,
      iat: Math.floor(Date.now() / 1000) - 301,
    }).catch((error: unknown) => error);

    expect(result).toMatchObject({ code: 'UNAUTHORIZED' });
    expect(session.claimBiometricEnrollment).not.toHaveBeenCalled();
  });

  it('rejects a second enrollment from the same access-token session', async () => {
    const session = {
      claimBiometricEnrollment: jest.fn().mockResolvedValueOnce(true).mockResolvedValueOnce(false),
      generateBiometric: jest.fn().mockReturnValue('biometric-token'),
    };
    const service = await createSubject(session);

    await service.enrollBiometricToken(user);
    const result = await service.enrollBiometricToken(user).catch((error: unknown) => error);

    expect(result).toMatchObject({ code: 'UNAUTHORIZED' });
  });
});
