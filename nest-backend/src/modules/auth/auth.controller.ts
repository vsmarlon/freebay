import {
  Controller,
  Body,
  Query,
  HttpStatus,
  Request,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { RegisterDTO, LoginDTO, UsernameAvailabilityQueryDTO, BiometricLoginDTO, GoogleAuthDTO, CompleteProfileDTO } from './dtos/auth.dto';
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
} from './dtos/auth-response.class';
import {
  GetPublic,
  PostPublic,
  PostAuth,
  PatchAuth,
  CurrentUser,
  CurrentUserId,
} from '@/shared/decorators';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { AllowTokenTypes } from './guards/token-types.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  @PostPublic('register', {
    summary: 'Register new user',
    description: 'Creates account and returns JWT access + refresh tokens',
    bodyType: RegisterDTO,
    responseType: AuthSessionResponse,
    responseStatus: 201,
    errors: [{ status: 409, description: 'Email already exists' }],
    throttle: { short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } },
    httpCode: HttpStatus.CREATED,
  })
  async register(@Body() body: RegisterDTO) {
    return this.authService.register(body);
  }

  @GetPublic('username-available', {
    summary: 'Check username availability',
    description: 'Returns whether a username is valid and not already taken',
    throttle: { short: { limit: 10, ttl: 10000 }, medium: { limit: 60, ttl: 60000 } },
  })
  async usernameAvailable(@Query() query: UsernameAvailabilityQueryDTO) {
    return this.authService.checkUsernameAvailability(query);
  }

  @PostPublic('login', {
    summary: 'Login',
    description: 'Authenticate with email and password',
    bodyType: LoginDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid credentials' }],
    throttle: { short: { limit: 10, ttl: 60000 }, medium: { limit: 30, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async login(@Body() body: LoginDTO) {
    return this.authService.login(body);
  }

  @PostPublic('google', {
    summary: 'Google OAuth login',
    description: 'Authenticate with a Google ID token. Links to existing account if email matches, or creates a new account.',
    bodyType: GoogleAuthDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid Google token' }],
    throttle: { short: { limit: 10, ttl: 60000 }, medium: { limit: 30, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async googleAuth(@Body() body: GoogleAuthDTO) {
    return this.authService.googleAuth(body.idToken);
  }

  @PostAuth('complete-profile', {
    summary: 'Complete user profile',
    description: 'Sets username, display name and other details after Google OAuth registration',
    bodyType: CompleteProfileDTO,
    responseType: AuthSessionResponse,
  })
  async completeProfile(@CurrentUserId() userId: string, @Body() body: CompleteProfileDTO) {
    return this.authService.completeProfile(userId, body);
  }

  @PostAuth('refresh', {
    summary: 'Refresh token',
    description: 'Exchanges a valid refresh token for a new access + refresh token pair',
    responseType: TokenRefreshResponse,
  })
  @AllowTokenTypes(JwtTokenType.REFRESH)
  async refresh(@CurrentUser() user: AuthUser) {
    return this.authService.refresh(user);
  }

  @PostAuth('logout', {
    summary: 'Logout',
    description: 'Blacklists current JWT tokens',
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS, JwtTokenType.REFRESH)
  async logout(@Request() req: { user: AuthUser }, @Body('refreshToken') refreshToken?: string) {
    let refreshTokenPayload: JwtPayload | undefined;
    if (refreshToken) {
      try {
        const payload = this.jwtService.decode(refreshToken) as JwtPayload | null;
        if (payload?.type === JwtTokenType.REFRESH && payload.userId === req.user.userId) {
          refreshTokenPayload = payload;
        }
      } catch { void 0; }
    }
    return this.authService.logout({ jti: req.user.jti, exp: req.user.exp }, refreshTokenPayload);
  }

  @PostPublic('forgot-password', {
    summary: 'Request password recovery',
    description: 'Sends password recovery code to the given email',
    bodyType: RequestPasswordRecoveryDTO,
    httpCode: HttpStatus.OK,
  })
  async forgotPassword(@Body() body: RequestPasswordRecoveryDTO) {
    return this.authService.forgotPassword(body);
  }

  @PostPublic('verify-reset-code', {
    summary: 'Verify password recovery code',
    description: 'Checks if the 6-digit recovery code is valid',
    bodyType: VerifyPasswordRecoveryCodeDTO,
    httpCode: HttpStatus.OK,
  })
  async verifyResetCode(@Body() body: VerifyPasswordRecoveryCodeDTO) {
    return this.authService.verifyResetCode(body);
  }

  @PostPublic('reset-password', {
    summary: 'Reset password',
    description: 'Resets password using verified recovery code',
    bodyType: ResetPasswordDTO,
    httpCode: HttpStatus.OK,
  })
  async resetPassword(@Body() body: ResetPasswordDTO) {
    return this.authService.resetPassword(body);
  }

  @PostPublic('biometric-login', {
    summary: 'Biometric login',
    description: 'Authenticate using a backend-issued biometric token. Returns a fresh token set including a rotated biometric token — store the new biometricToken in the device keychain.',
    bodyType: BiometricLoginDTO,
    responseType: BiometricSessionResponse,
    errors: [{ status: 401, description: 'Invalid or revoked biometric token' }],
    throttle: { short: { limit: 5, ttl: 60000 }, medium: { limit: 15, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async biometricLogin(@Body() body: BiometricLoginDTO) {
    return this.authService.biometricLogin(body.biometricToken);
  }

  @PatchAuth('biometric-token/revoke', {
    summary: 'Revoke biometric token',
    description: 'Blacklists the current biometric token so it can no longer be used. Call this when the user disables biometric login.',
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.BIOMETRIC)
  async revokeBiometricToken(@CurrentUser() user: AuthUser) {
    return this.authService.revokeBiometricToken(user.jti, user.exp);
  }
}
