import { BiometricChallengePurpose } from '@/shared/auth/biometric-credential.service';
import {
  Controller,
  Body,
  Query,
  HttpStatus,
  Request,
  UnauthorizedException,
  ParseUUIDPipe,
  Res,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GoogleAuthUseCase } from './usecases/google-auth.usecase';
import { AppleAuthUseCase } from './usecases/apple-auth.usecase';
import { CompleteProfileUseCase } from './usecases/complete-profile.usecase';
import { RefreshMobileSessionUseCase } from './usecases/refresh-mobile-session.usecase';
import { LogoutSessionUseCase } from './usecases/logout-session.usecase';
import { CheckUsernameAvailabilityUseCase } from './usecases/check-username-availability.usecase';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { BiometricLoginUseCase } from './usecases/biometric-login.usecase';
import { EnrollBiometricUseCase } from './usecases/enroll-biometric.usecase';
import { RevokeBiometricUseCase } from './usecases/revoke-biometric.usecase';
import { CreateBiometricChallengeUseCase } from './usecases/create-biometric-challenge.usecase';
import { CreateBiometricEnrollmentChallengeUseCase } from './usecases/create-biometric-enrollment-challenge.usecase';
import { CreateStepUpUseCase } from './usecases/create-step-up.usecase';
import { RequestEmailVerificationUseCase } from './usecases/request-email-verification.usecase';
import { ConfirmEmailVerificationUseCase } from './usecases/confirm-email-verification.usecase';
import {
  RequestEmailVerificationDTO,
  ConfirmEmailVerificationDTO,
} from './dtos/email-verification.dto';
import { RegisterDTO, LoginDTO, UsernameAvailabilityQueryDTO, BiometricLoginDTO, BiometricTokenDTO, BiometricChallengeDTO, BiometricEnrollmentDTO, BiometricEnrollmentChallengeDTO, StepUpDTO, GoogleAuthDTO, AppleAuthDTO, CompleteProfileDTO } from './dtos/auth.dto';
import {
  RequestPasswordRecoveryDTO,
  VerifyPasswordRecoveryCodeDTO,
  ResetPasswordDTO,
} from './dtos/password-recovery.dto';
import {
  AuthSessionResponse,
  TokenRefreshResponse,
  MessageResponse,
  BiometricSessionResponse,
  BiometricEnrollmentResponse,
} from './dtos/auth-response.class';
import {
  GetPublic,
  PostPublic,
  PostAuth,
  PatchAuth,
  CurrentUser,
  CurrentUserId,
} from '@/shared/decorators';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { AllowTokenTypes } from './guards/token-types.decorator';
import { ownedPayload } from './utils/web-session-cookies';
import { THROTTLE_TTL_MINUTE_MS, THROTTLE_TTL_TEN_SECONDS_MS } from '@/shared/http/throttle.constants';
import { unwrap } from '@/shared/http/unwrap';
import { ConfigService } from '@nestjs/config';
import { StrictOrigin } from '@/shared/decorators';
import { setWebSessionCookies } from './utils/web-session-cookies';
import type { Response } from 'express';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly googleAuthUseCase: GoogleAuthUseCase,
    private readonly appleAuthUseCase: AppleAuthUseCase,
    private readonly completeProfileUseCase: CompleteProfileUseCase,
    private readonly refreshMobileSessionUseCase: RefreshMobileSessionUseCase,
    private readonly logoutSessionUseCase: LogoutSessionUseCase,
    private readonly checkUsernameAvailabilityUseCase: CheckUsernameAvailabilityUseCase,
    private readonly requestPasswordRecoveryUseCase: RequestPasswordRecoveryUseCase,
    private readonly verifyPasswordRecoveryCodeUseCase: VerifyPasswordRecoveryCodeUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly biometricLoginUseCase: BiometricLoginUseCase,
    private readonly enrollBiometricUseCase: EnrollBiometricUseCase,
    private readonly revokeBiometricUseCase: RevokeBiometricUseCase,
    private readonly jwtService: JwtService,
    private readonly createBiometricChallengeUseCase: CreateBiometricChallengeUseCase,
    private readonly createStepUpUseCase: CreateStepUpUseCase,
    private readonly configService: ConfigService,
    private readonly createBiometricEnrollmentChallengeUseCase: CreateBiometricEnrollmentChallengeUseCase,
    private readonly requestEmailVerificationUseCase: RequestEmailVerificationUseCase,
    private readonly confirmEmailVerificationUseCase: ConfirmEmailVerificationUseCase,
  ) {}

  @PostPublic('register', {
    summary: 'Register new user',
    description: 'Creates account and returns JWT access + refresh tokens',
    bodyType: RegisterDTO,
    responseType: AuthSessionResponse,
    responseStatus: 201,
    errors: [{ status: 409, description: 'Email already exists' }],
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 20, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.CREATED,
  })
  async register(@Body() body: RegisterDTO) {
    return unwrap(await this.registerUseCase.execute(body));
  }

  @PostPublic('web/register', {
    summary: 'Register and start a browser session',
    bodyType: RegisterDTO,
    httpCode: HttpStatus.CREATED,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 20, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async webRegister(@Body() body: RegisterDTO, @Res({ passthrough: true }) response: Response) {
    const session = unwrap(await this.registerUseCase.execute(body));
    setWebSessionCookies(response, this.configService.get('NODE_ENV') === 'production', session.token, session.refreshToken);
    return { user: session.user };
  }

  @GetPublic('username-available', {
    summary: 'Check username availability',
    description: 'Returns whether a username is valid and not already taken',
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_TEN_SECONDS_MS }, medium: { limit: 60, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  async usernameAvailable(@Query() query: UsernameAvailabilityQueryDTO) {
    return unwrap(await this.checkUsernameAvailabilityUseCase.execute({ username: query.u }));
  }

  @PostPublic(BiometricChallengePurpose.LOGIN, {
    summary: BiometricChallengePurpose.LOGIN,
    description: 'Authenticate with email and password',
    bodyType: LoginDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid credentials' }],
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async login(@Body() body: LoginDTO) {
    return unwrap(await this.loginUseCase.execute(body));
  }

  @PostPublic('web/login', {
    summary: 'Sign in to the browser session with email and password',
    bodyType: LoginDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async webLogin(@Body() body: LoginDTO, @Res({ passthrough: true }) response: Response) {
    const session = unwrap(await this.loginUseCase.execute(body));
    setWebSessionCookies(response, this.configService.get('NODE_ENV') === 'production', session.token, session.refreshToken);
    return { user: session.user };
  }

  @PostPublic('google', {
    summary: 'Google OAuth login',
    description: 'Authenticate with a Google ID token. Links to existing account if email matches, or creates a new account.',
    bodyType: GoogleAuthDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid Google token' }],
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async googleAuth(@Body() body: GoogleAuthDTO) {
    return unwrap(await this.googleAuthUseCase.execute(body.idToken));
  }

  @PostPublic('web/google', {
    summary: 'Sign in to the browser session with Google',
    bodyType: GoogleAuthDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async webGoogleAuth(@Body() body: GoogleAuthDTO, @Res({ passthrough: true }) response: Response) {
    const session = unwrap(await this.googleAuthUseCase.execute(body.idToken));
    setWebSessionCookies(response, this.configService.get('NODE_ENV') === 'production', session.token, session.refreshToken);
    return { user: session.user };
  }

  @PostAuth('complete-profile', {
    summary: 'Complete user profile',
    description: 'Sets username, display name and other details after Google OAuth registration',
    bodyType: CompleteProfileDTO,
    responseType: AuthSessionResponse,
  })
  async completeProfile(@CurrentUserId() userId: string, @Body() body: CompleteProfileDTO) {
    return unwrap(await this.completeProfileUseCase.execute(userId, body));
  }

  @PostAuth('refresh', {
    summary: 'Refresh token',
    description: 'Exchanges a valid refresh token for a new access + refresh token pair',
    responseType: TokenRefreshResponse,
  })
  @AllowTokenTypes(JwtTokenType.REFRESH)
  async refresh(@CurrentUser() user: AuthUser) {
    return unwrap(await this.refreshMobileSessionUseCase.execute(user));
  }

  @PostPublic('apple', {
    summary: 'Sign in with Apple',
    description: 'Validates the Apple identity token and exchanges its single-use authorization code.',
    bodyType: AppleAuthDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid Apple token or nonce' }, { status: 409, description: 'Email belongs to another account' }],
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async appleAuth(@Body() body: AppleAuthDTO) {
    return unwrap(await this.appleAuthUseCase.execute(body));
  }

  @PostPublic('web/apple', {
    summary: 'Sign in to the browser session with Apple',
    bodyType: AppleAuthDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async webAppleAuth(@Body() body: AppleAuthDTO, @Res({ passthrough: true }) response: Response) {
    const session = unwrap(await this.appleAuthUseCase.execute(body, true));
    setWebSessionCookies(response, this.configService.get('NODE_ENV') === 'production', session.token, session.refreshToken);
    return { user: session.user };
  }

  @PostAuth('logout', {
    summary: 'Logout',
    description: 'Blacklists current JWT tokens',
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS, JwtTokenType.REFRESH)
  async logout(
    @Request() req: { user: AuthUser },
    @Body('refreshToken') refreshToken?: string,
    @Body('biometricToken') biometricToken?: string,
    @Body('installationId', new ParseUUIDPipe({ version: '4', optional: true })) installationId?: string,
  ) {
    const refreshTokenPayload = ownedPayload(this.jwtService,
      refreshToken,
      JwtTokenType.REFRESH,
      req.user.userId,
    );
    const biometricTokenPayload = ownedPayload(this.jwtService,
      biometricToken,
      JwtTokenType.BIOMETRIC,
      req.user.userId,
    );
    return unwrap(await this.logoutSessionUseCase.execute([
      req.user,
      refreshTokenPayload,
      biometricTokenPayload,
    ], installationId ? { userId: req.user.userId, installationId } : undefined));
  }

  @PostPublic('forgot-password', {
    summary: 'Request password recovery',
    description: 'Sends password recovery code to the given email',
    bodyType: RequestPasswordRecoveryDTO,
    httpCode: HttpStatus.OK,
  })
  async forgotPassword(@Body() body: RequestPasswordRecoveryDTO) {
    const result = await this.requestPasswordRecoveryUseCase.execute(body);
    unwrap(result);
    return { sent: true };
  }

  @PostPublic('verify-reset-code', {
    summary: 'Verify password recovery code',
    description: 'Checks if the 6-digit recovery code is valid',
    bodyType: VerifyPasswordRecoveryCodeDTO,
    httpCode: HttpStatus.OK,
  })
  async verifyResetCode(@Body() body: VerifyPasswordRecoveryCodeDTO) {
    const result = await this.verifyPasswordRecoveryCodeUseCase.execute(body);
    unwrap(result);
    return { verified: true };
  }

  @PostPublic('reset-password', {
    summary: 'Reset password',
    description: 'Resets password using verified recovery code',
    bodyType: ResetPasswordDTO,
    httpCode: HttpStatus.OK,
  })
  async resetPassword(@Body() body: ResetPasswordDTO) {
    const result = await this.resetPasswordUseCase.execute(body);
    unwrap(result);
    return { reset: true };
  }

  @PostPublic('biometric-login', {
    summary: 'Biometric login',
    description: 'Authenticates a one-time challenge with the registered non-exportable P-256 key and rotates the session family.',
    bodyType: BiometricLoginDTO,
    responseType: BiometricSessionResponse,
    errors: [{ status: 401, description: 'Invalid or revoked biometric token' }],
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async biometricLogin(@Body() body: BiometricLoginDTO) {
    return unwrap(await this.biometricLoginUseCase.execute(body));
  }

  @PostPublic('biometric-challenge', {
    summary: 'Create a one-time biometric signature challenge',
    bodyType: BiometricChallengeDTO,
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async biometricChallenge(@Body() body: BiometricChallengeDTO) {
    return unwrap(await this.createBiometricChallengeUseCase.execute(body));
  }

  @PostAuth('step-up', {
    summary: 'Prove recent authentication for a sensitive action',
    bodyType: StepUpDTO,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  async stepUp(@CurrentUser() user: AuthUser, @Body() body: StepUpDTO) {
    return unwrap(await this.createStepUpUseCase.execute(user, body));
  }

  @PostAuth('biometric-token/enroll/challenge', {
    summary: 'Create a session-bound biometric enrollment signature challenge',
    bodyType: BiometricEnrollmentChallengeDTO,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
    httpCode: HttpStatus.OK,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  async biometricEnrollmentChallenge(@CurrentUser() user: AuthUser, @Body() body: BiometricEnrollmentChallengeDTO) {
    return unwrap(await this.createBiometricEnrollmentChallengeUseCase.execute(user, body.publicKey));
  }

  @PostAuth('biometric-token/enroll', {
    summary: 'Enroll biometric login',
    description: 'Registers a P-256 public key after a session-bound signature challenge or legacy biometric_enroll step-up proof and issues a bound biometric token.',
    bodyType: BiometricEnrollmentDTO,
    responseType: BiometricEnrollmentResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  async enrollBiometricToken(@CurrentUser() user: AuthUser, @Body() body: BiometricEnrollmentDTO) {
    return unwrap(await this.enrollBiometricUseCase.execute(user, body.stepUpToken, body.publicKey, body.challengeId, body.signature));
  }

  @PostAuth('verify-email/request', {
    summary: 'Request email verification',
    description: 'Sends the email verification link to the current account',
    bodyType: RequestEmailVerificationDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  async requestEmailVerification(@CurrentUserId() userId: string, @Body() body: RequestEmailVerificationDTO) {
    return unwrap(await this.requestEmailVerificationUseCase.execute(userId, body.locale ?? 'pt-BR'));
  }

  @PostAuth('verify-email/confirm', {
    summary: 'Confirm email verification',
    description: 'Consumes the email verification token and marks the account email as verified',
    bodyType: ConfirmEmailVerificationDTO,
    httpCode: HttpStatus.OK,
    errors: [
      { status: 404, description: 'Invalid, expired or replayed verification token' },
      { status: 429, description: 'Verification attempts exceeded' },
    ],
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  async confirmEmailVerification(@CurrentUserId() userId: string, @Body() body: ConfirmEmailVerificationDTO) {
    return unwrap(await this.confirmEmailVerificationUseCase.execute(userId, body.token));
  }

  @PatchAuth('biometric-token/revoke', {
    summary: 'Revoke biometric token',
    description: 'Blacklists a biometric token so it can no longer be used. Authenticate with the access token and send the biometric token in the body. Call this when the user disables biometric login.',
    bodyType: BiometricTokenDTO,
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  async revokeBiometricToken(
    @CurrentUser() user: AuthUser,
    @Body() body: BiometricTokenDTO,
  ) {
    const payload = ownedPayload(this.jwtService,
      body.biometricToken,
      JwtTokenType.BIOMETRIC,
      user.userId,
    );
    if (!payload) {
      throw new UnauthorizedException('Token biométrico inválido');
    }
    if (!payload.jti || !payload.exp) {
      throw new UnauthorizedException('Token biométrico inválido');
    }
    if (!payload.sid) throw new UnauthorizedException('Token biométrico inválido');
    return unwrap(await this.revokeBiometricUseCase.execute({ jti: payload.jti, exp: payload.exp, sid: payload.sid }));
  }
}
