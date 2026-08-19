import {
  Controller,
  Post,
  Get,
  Delete,
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
  GuestSessionResponse,
  TokenRefreshResponse,
  MessageResponse,
  BiometricSessionResponse,
} from './dtos/auth-response.class';
import { PublicEndpoint, Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
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

  @Post('register')
  @PublicEndpoint({
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

  @Get('username-available')
  @PublicEndpoint({
    summary: 'Check username availability',
    description: 'Returns whether a username is valid and not already taken',
    throttle: { short: { limit: 10, ttl: 10000 }, medium: { limit: 60, ttl: 60000 } },
  })
  async usernameAvailable(@Query() query: UsernameAvailabilityQueryDTO) {
    return this.authService.checkUsernameAvailability(query);
  }

  @Post('login')
  @PublicEndpoint({
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

  @Post('google')
  @PublicEndpoint({
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

  @Post('complete-profile')
  @Authenticated({
    summary: 'Complete user profile',
    description: 'Sets username, display name and other details after Google OAuth registration',
    bodyType: CompleteProfileDTO,
    responseType: AuthSessionResponse,
    guards: [JwtAuthGuard],
  })
  async completeProfile(@CurrentUser() user: AuthUser, @Body() body: CompleteProfileDTO) {
    return this.authService.completeProfile(user.userId, body);
  }

  @Post('guest')
  @PublicEndpoint({
    summary: 'Create guest session',
    description: 'Creates temporary guest user and returns JWT token',
    responseType: GuestSessionResponse,
    throttle: { short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async guest() {
    return this.authService.guest();
  }

  @Post('refresh')
  @AllowTokenTypes(JwtTokenType.REFRESH)
  @Authenticated({
    summary: 'Refresh token',
    description: 'Exchanges a valid refresh token for a new access + refresh token pair',
    responseType: TokenRefreshResponse,
    guards: [JwtAuthGuard],
  })
  async refresh(@CurrentUser() user: AuthUser) {
    return this.authService.refresh(user);
  }

  @Delete('logout')
  @AllowTokenTypes(JwtTokenType.REFRESH)
  @Authenticated({
    summary: 'Logout',
    description: 'Blacklists current JWT tokens',
    responseType: MessageResponse,
    guards: [JwtAuthGuard],
  })
  async logout(@Request() req: any, @Body('refreshToken') refreshToken?: string) {
    let refreshTokenPayload: any = undefined;
    if (refreshToken) {
      try {
        const payload = this.jwtService.decode(refreshToken) as any;
        if (payload.type === JwtTokenType.REFRESH && payload.userId === req.user.userId) {
          refreshTokenPayload = payload;
        }
      } catch { void 0; }
    }
    return this.authService.logout({ jti: req.user.jti, exp: req.user.exp }, refreshTokenPayload);
  }

  @Post('forgot-password')
  @PublicEndpoint({
    summary: 'Request password recovery',
    description: 'Sends password recovery code to the given email',
    bodyType: RequestPasswordRecoveryDTO,
    httpCode: HttpStatus.OK,
  })
  async forgotPassword(@Body() body: RequestPasswordRecoveryDTO) {
    return this.authService.forgotPassword(body);
  }

  @Post('verify-reset-code')
  @PublicEndpoint({
    summary: 'Verify password recovery code',
    description: 'Checks if the 6-digit recovery code is valid',
    bodyType: VerifyPasswordRecoveryCodeDTO,
    httpCode: HttpStatus.OK,
  })
  async verifyResetCode(@Body() body: VerifyPasswordRecoveryCodeDTO) {
    return this.authService.verifyResetCode(body);
  }

  @Post('reset-password')
  @PublicEndpoint({
    summary: 'Reset password',
    description: 'Resets password using verified recovery code',
    bodyType: ResetPasswordDTO,
    httpCode: HttpStatus.OK,
  })
  async resetPassword(@Body() body: ResetPasswordDTO) {
    return this.authService.resetPassword(body);
  }

  @Post('biometric-login')
  @PublicEndpoint({
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

  @Delete('biometric-token')
  @AllowTokenTypes(JwtTokenType.BIOMETRIC)
  @Authenticated({
    summary: 'Revoke biometric token',
    description: 'Blacklists the current biometric token so it can no longer be used. Call this when the user disables biometric login.',
    responseType: MessageResponse,
    guards: [JwtAuthGuard],
  })
  async revokeBiometricToken(@CurrentUser() user: AuthUser) {
    return this.authService.revokeBiometricToken(user.jti, user.exp);
  }
}
