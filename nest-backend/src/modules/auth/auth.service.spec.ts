import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { right } from '@/shared/core/either';
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

describe('AuthService legacy refresh', () => {
  it('claims biometric replay exactly once without a post-claim revoke', async () => {
    let claimed = false;
    const sessions = {
      generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }),
      generateBiometric: jest.fn().mockReturnValue('biometric'),
      revoke: jest.fn(),
      claimBiometric: jest.fn().mockImplementation(async () => {
        if (claimed) return false;
        claimed = true;
        return true;
      }),
    };
    const biometric = {
      execute: jest.fn().mockResolvedValue(right({
        user: { id: 'u1', role: 'USER' },
        jti: 'j1',
        exp: Math.floor(Date.now() / 1000) + 60,
      })),
    };
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UserDatabaseRepository, useValue: {} },
        { provide: SessionTokenService, useValue: sessions },
        ...[RegisterUseCase, LoginUseCase, RequestPasswordRecoveryUseCase, VerifyPasswordRecoveryCodeUseCase, ResetPasswordUseCase, CheckUsernameAvailabilityUseCase, GoogleAuthUseCase, CompleteProfileUseCase, RequestMagicLinkUseCase, ConsumeMagicLinkUseCase, RefreshWebSessionUseCase, LogoutWebSessionUseCase].map((token) => ({ provide: token, useValue: {} })),
        { provide: BiometricLoginUseCase, useValue: biometric },
        { provide: JwtService, useValue: {} },
      ],
    }).compile();

    const results = await Promise.allSettled([
      module.get(AuthService).biometricLogin('claimed-token'),
      module.get(AuthService).biometricLogin('claimed-token'),
    ]);

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(sessions.claimBiometric).toHaveBeenCalledTimes(2);
    expect(sessions.revoke).not.toHaveBeenCalled();
  });

  it('allows exactly one concurrent rotation for the same refresh token', async () => {
    let claimed = false;
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: 'USER', suspendedAt: null })) };
    const sessions = {
      claimRefresh: jest.fn().mockImplementation(async () => {
        if (claimed) return false;
        claimed = true;
        return true;
      }),
      revoke: jest.fn().mockResolvedValue(undefined),
      generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }),
    };
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: SessionTokenService, useValue: sessions },
        ...[RegisterUseCase, LoginUseCase, RequestPasswordRecoveryUseCase, VerifyPasswordRecoveryCodeUseCase, ResetPasswordUseCase, CheckUsernameAvailabilityUseCase, BiometricLoginUseCase, GoogleAuthUseCase, CompleteProfileUseCase, RequestMagicLinkUseCase, ConsumeMagicLinkUseCase, RefreshWebSessionUseCase, LogoutWebSessionUseCase].map((token) => ({ provide: token, useValue: {} })),
        { provide: JwtService, useValue: {} },
      ],
    }).compile();

    const payload = { userId: 'u1', type: JwtTokenType.REFRESH, jti: 'j1', exp: Math.floor(Date.now() / 1000) + 60 };
    const results = await Promise.allSettled([module.get(AuthService).refresh(payload), module.get(AuthService).refresh(payload)]);

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(sessions.claimRefresh).toHaveBeenCalledTimes(2);
  });
});
