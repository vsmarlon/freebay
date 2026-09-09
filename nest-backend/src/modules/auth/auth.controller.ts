import {
  Controller,
  Body,
  Query,
  HttpStatus,
  Request,
  UnauthorizedException,
  Res,
  UseGuards,
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
import { WebCookieAuth } from './guards/web-cookie-auth.decorator';
import { WebOriginGuard } from './guards/web-origin.guard';
import { RequestMagicLinkDTO, ConsumeMagicLinkDTO } from './dtos/magic-link.dto';
import { getWebSessionCookie, WEB_REFRESH_COOKIE } from './utils/web-session-cookies';
import type { Request as ExpressRequest, Response } from 'express';

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

  @PostPublic('web/magic-link/request', {
    summary: 'Request web magic link',
    bodyType: RequestMagicLinkDTO,
    httpCode: HttpStatus.OK,
  })
  @UseGuards(WebOriginGuard)
  async requestWebMagicLink(@Request() req: ExpressRequest, @Body() body: RequestMagicLinkDTO) {
    return this.authService.requestMagicLink({
      ...body,
      ip: req.ip ?? 'unknown',
      userAgent: req.headers['user-agent'],
    });
  }

  @PostPublic('web/magic-link/consume', {
    summary: 'Consume web magic link',
    bodyType: ConsumeMagicLinkDTO,
    httpCode: HttpStatus.OK,
  })
  @UseGuards(WebOriginGuard)
  async consumeWebMagicLink(@Body() body: ConsumeMagicLinkDTO, @Res({ passthrough: true }) response: Response) {
    const result = await this.authService.consumeMagicLink(body);
    this.setSessionCookies(response, result.tokens.token, result.tokens.refreshToken);
    return { user: result.user };
  }

  @PostAuth('web/session/refresh', {
    summary: 'Refresh web session',
    httpCode: HttpStatus.OK,
  })
  @AllowTokenTypes(JwtTokenType.REFRESH)
  @WebCookieAuth()
  @UseGuards(WebOriginGuard)
  async refreshWebSession(@CurrentUser() user: AuthUser, @Res({ passthrough: true }) response: Response) {
    const tokens = await this.authService.refreshWebSession(user);
    this.setSessionCookies(response, tokens.token, tokens.refreshToken);
    return { refreshed: true };
  }

  @PostAuth('web/session/logout', {
    summary: 'Logout web session',
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  @WebCookieAuth()
  @UseGuards(WebOriginGuard)
  async logoutWebSession(@Request() req: ExpressRequest & { user: AuthUser }, @Res({ passthrough: true }) response: Response) {
    const refreshPayload = this._ownedPayload(getWebSessionCookie(req.headers.cookie, WEB_REFRESH_COOKIE), JwtTokenType.REFRESH, req.user.userId);
    const result = await this.authService.logoutWebSession([req.user, refreshPayload]);
    this.clearSessionCookies(response);
    return result;
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
  ) {
    const refreshTokenPayload = this._ownedPayload(
      refreshToken,
      JwtTokenType.REFRESH,
      req.user.userId,
    );
    const biometricTokenPayload = this._ownedPayload(
      biometricToken,
      JwtTokenType.BIOMETRIC,
      req.user.userId,
    );
    return this.authService.logout(
      { jti: req.user.jti, exp: req.user.exp },
      refreshTokenPayload,
      biometricTokenPayload,
    );
  }

  private _ownedPayload(
    token: string | undefined,
    type: JwtTokenType,
    userId: string,
  ): JwtPayload | undefined {
    if (!token) return undefined;
    try {
      const payload = this.jwtService.verify<JwtPayload>(token);
      if (payload?.type === type && payload.userId === userId) return payload;
    } catch { void 0; }
    return undefined;
  }

  private setSessionCookies(response: Response, access: string, refresh: string): void {
    const secure = this.configService.get('NODE_ENV') === 'production';
    const flags = `HttpOnly; ${secure ? 'Secure; ' : ''}SameSite=Lax`;
    response.setHeader('Set-Cookie', [
      `freebay_access=${encodeURIComponent(access)}; Path=/; Max-Age=900; ${flags}`,
      `freebay_refresh=${encodeURIComponent(refresh)}; Path=/auth/web/session; Max-Age=604800; ${flags}`,
    ]);
  }

  private clearSessionCookies(response: Response): void {
    const secure = this.configService.get('NODE_ENV') === 'production';
    const flags = `HttpOnly; ${secure ? 'Secure; ' : ''}SameSite=Lax`;
    response.setHeader('Set-Cookie', [
      `freebay_access=; Path=/; Max-Age=0; ${flags}`,
      `freebay_refresh=; Path=/auth/web/session; Max-Age=0; ${flags}`,
    ]);
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
    description: 'Blacklists a biometric token so it can no longer be used. Authenticate with the access token and send the biometric token in the body. Call this when the user disables biometric login.',
    bodyType: BiometricLoginDTO,
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  async revokeBiometricToken(
    @CurrentUser() user: AuthUser,
    @Body() body: BiometricLoginDTO,
  ) {
    const payload = this._ownedPayload(
      body.biometricToken,
      JwtTokenType.BIOMETRIC,
      user.userId,
    );
    if (!payload) {
      throw new UnauthorizedException('Token biométrico inválido');
    }
    return this.authService.revokeBiometricToken(payload.jti, payload.exp);
  }
}
