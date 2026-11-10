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
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';
import { MagicLinkDatabaseRepository } from '../data/repositories/magic-link-database.repository';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { RequestMagicLinkUseCase } from './request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './logout-web-session.usecase';
import { RefreshMobileSessionUseCase } from './refresh-mobile-session.usecase';
import { LogoutSessionUseCase } from './logout-session.usecase';
import { EnrollBiometricUseCase } from './enroll-biometric.usecase';
import { RevokeBiometricUseCase } from './revoke-biometric.usecase';
import { SessionTokenService } from '../services/session-token.service';
import { AppleAuthUseCase } from './apple-auth.usecase';
import { CreateBiometricChallengeUseCase } from './create-biometric-challenge.usecase';
import { CreateBiometricEnrollmentChallengeUseCase } from './create-biometric-enrollment-challenge.usecase';
import { CreateStepUpUseCase } from './create-step-up.usecase';
import { RequestWebStepUpMagicLinkUseCase } from './request-web-step-up-magic-link.usecase';
import { RequestWebPasswordResetUseCase } from './request-web-password-reset.usecase';
import { ResetWebPasswordUseCase } from './reset-web-password.usecase';
import { RequestEmailVerificationUseCase } from './request-email-verification.usecase';
import { ConfirmEmailVerificationUseCase } from './confirm-email-verification.usecase';
import { EmailVerificationGateService } from '../services/email-verification-gate.service';

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
    AppleAuthUseCase,
    CompleteProfileUseCase,
    ResendService,
    MagicLinkDatabaseRepository,
    { provide: MagicLinkRepository, useExisting: MagicLinkDatabaseRepository },
    SessionTokenService,
    RequestMagicLinkUseCase,
    ConsumeMagicLinkUseCase,
    RefreshWebSessionUseCase,
    LogoutWebSessionUseCase,
    RefreshMobileSessionUseCase,
    LogoutSessionUseCase,
    EnrollBiometricUseCase,
    RevokeBiometricUseCase,
    CreateBiometricChallengeUseCase,
    CreateBiometricEnrollmentChallengeUseCase,
    CreateStepUpUseCase,
    RequestWebStepUpMagicLinkUseCase,
    RequestWebPasswordResetUseCase,
    ResetWebPasswordUseCase,
    RequestEmailVerificationUseCase,
    ConfirmEmailVerificationUseCase,
    EmailVerificationGateService,
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
    AppleAuthUseCase,
    CompleteProfileUseCase,
    ResendService,
    RequestMagicLinkUseCase,
    ConsumeMagicLinkUseCase,
    RefreshWebSessionUseCase,
    LogoutWebSessionUseCase,
    RefreshMobileSessionUseCase,
    LogoutSessionUseCase,
    EnrollBiometricUseCase,
    RevokeBiometricUseCase,
    SessionTokenService,
    CreateBiometricChallengeUseCase,
    CreateBiometricEnrollmentChallengeUseCase,
    CreateStepUpUseCase,
    RequestWebStepUpMagicLinkUseCase,
    RequestWebPasswordResetUseCase,
    ResetWebPasswordUseCase,
    RequestEmailVerificationUseCase,
    ConfirmEmailVerificationUseCase,
    EmailVerificationGateService,
  ],
})
export class AuthUseCasesModule {}
