import { Module } from '@nestjs/common';
import { RegisterUseCase } from './register.usecase';
import { LoginUseCase } from './login.usecase';
import { RequestPasswordRecoveryUseCase } from './request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './reset-password.usecase';
import { CheckUsernameAvailabilityUseCase } from './check-username-availability.usecase';
import { BiometricLoginUseCase } from './biometric-login.usecase';
import { GoogleAuthUseCase } from './google-auth.usecase';
import { CompleteProfileUseCase } from './complete-profile.usecase';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';
import { MagicLinkDatabaseRepository } from '../data/repositories/magic-link-database.repository';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { RequestMagicLinkUseCase } from './request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './logout-web-session.usecase';
import { SessionTokenService } from '../services/session-token.service';

@Module({
  providers: [
    UserDatabaseRepository,
    PasswordRecoveryDatabaseRepository,
    RegisterUseCase,
    LoginUseCase,
    RequestPasswordRecoveryUseCase,
    VerifyPasswordRecoveryCodeUseCase,
    ResetPasswordUseCase,
    CheckUsernameAvailabilityUseCase,
    BiometricLoginUseCase,
    GoogleAuthUseCase,
    CompleteProfileUseCase,
    ResendService,
    MagicLinkDatabaseRepository,
    { provide: MagicLinkRepository, useExisting: MagicLinkDatabaseRepository },
    SessionTokenService,
    RequestMagicLinkUseCase,
    ConsumeMagicLinkUseCase,
    RefreshWebSessionUseCase,
    LogoutWebSessionUseCase,
  ],
  exports: [
    UserDatabaseRepository,
    RegisterUseCase,
    LoginUseCase,
    RequestPasswordRecoveryUseCase,
    VerifyPasswordRecoveryCodeUseCase,
    ResetPasswordUseCase,
    CheckUsernameAvailabilityUseCase,
    BiometricLoginUseCase,
    GoogleAuthUseCase,
    CompleteProfileUseCase,
    ResendService,
    RequestMagicLinkUseCase,
    ConsumeMagicLinkUseCase,
    RefreshWebSessionUseCase,
    LogoutWebSessionUseCase,
    SessionTokenService,
  ],
})
export class AuthUseCasesModule {}
