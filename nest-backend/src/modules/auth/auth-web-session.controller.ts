import {
  Controller,
  Body,
  Request,
  HttpStatus,
  Res,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
import { CreateStepUpUseCase } from './usecases/create-step-up.usecase';
import { RequestWebStepUpMagicLinkUseCase } from './usecases/request-web-step-up-magic-link.usecase';
import { RequestWebPasswordResetUseCase } from './usecases/request-web-password-reset.usecase';
import { ResetWebPasswordUseCase } from './usecases/reset-web-password.usecase';
import { RequestWebPasswordResetDTO, ResetWebPasswordDTO } from './dtos/web-password-reset.dto';
import {
  PostPublic,
  PostAuth,
  CurrentUser,
  StrictOrigin,
} from '@/shared/decorators';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { AllowTokenTypes } from './guards/token-types.decorator';
import { WebCookieAuth } from './guards/web-cookie-auth.decorator';
import { MessageResponse } from './dtos/auth-response.class';
import { RequestMagicLinkDTO, ConsumeMagicLinkDTO, RequestStepUpMagicLinkDTO } from './dtos/magic-link.dto';
import { StepUpDTO } from './dtos/auth.dto';
import {
  getWebSessionCookie,
  WEB_ACCESS_COOKIE,
  WEB_REFRESH_COOKIE,
  ownedPayload,
  setWebSessionCookies,
  clearWebSessionCookies,
} from './utils/web-session-cookies';
import type { Request as ExpressRequest, Response } from 'express';
import { unwrap } from '@/shared/http/unwrap';
import { THROTTLE_TTL_MINUTE_MS } from '@/shared/http/throttle.constants';

@ApiTags('Auth')
@Controller('auth')
export class AuthWebSessionController {
  constructor(
    private readonly requestMagicLinkUseCase: RequestMagicLinkUseCase,
    private readonly consumeMagicLinkUseCase: ConsumeMagicLinkUseCase,
    private readonly refreshWebSessionUseCase: RefreshWebSessionUseCase,
    private readonly logoutWebSessionUseCase: LogoutWebSessionUseCase,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly createStepUpUseCase: CreateStepUpUseCase,
    private readonly requestWebStepUpMagicLinkUseCase: RequestWebStepUpMagicLinkUseCase,
    private readonly requestWebPasswordResetUseCase: RequestWebPasswordResetUseCase,
    private readonly resetWebPasswordUseCase: ResetWebPasswordUseCase,
  ) {}

  private get secure(): boolean {
    return this.configService.get('NODE_ENV') === 'production';
  }

  @PostAuth('web/step-up', { summary: 'Prove recent authentication for a sensitive web action', bodyType: StepUpDTO, httpCode: HttpStatus.OK })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  @WebCookieAuth()
  @StrictOrigin()
  async createWebStepUp(@CurrentUser() user: AuthUser, @Body() body: StepUpDTO) {
    return unwrap(await this.createStepUpUseCase.execute(user, body, { web: true }));
  }

  @PostAuth('web/step-up/magic-link/request', {
    summary: 'Request email proof for a sensitive web action',
    bodyType: RequestStepUpMagicLinkDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  @WebCookieAuth()
  @StrictOrigin()
  async requestWebStepUpMagicLink(
    @Request() req: ExpressRequest,
    @CurrentUser() user: AuthUser,
    @Body() body: RequestStepUpMagicLinkDTO,
  ) {
    const result = await this.requestWebStepUpMagicLinkUseCase.execute({
      user,
      body,
      ip: req.ip ?? 'unknown',
      userAgent: req.headers['user-agent'],
    });
    unwrap(result);
    return { sent: true };
  }

  @PostPublic('web/magic-link/request', {
    summary: 'Request web magic link',
    bodyType: RequestMagicLinkDTO,
    httpCode: HttpStatus.OK,
  })
  @StrictOrigin()
  async requestWebMagicLink(@Request() req: ExpressRequest, @Body() body: RequestMagicLinkDTO) {
    const result = await this.requestMagicLinkUseCase.execute({
      ...body,
      ip: req.ip ?? 'unknown',
      userAgent: req.headers['user-agent'],
      returnOrigin: req.headers.origin,
    });
    unwrap(result);
    return { sent: true };
  }

  @PostPublic('web/magic-link/consume', {
    summary: 'Consume web magic link',
    bodyType: ConsumeMagicLinkDTO,
    httpCode: HttpStatus.OK,
  })
  @StrictOrigin()
  async consumeWebMagicLink(@Body() body: ConsumeMagicLinkDTO, @Res({ passthrough: true }) response: Response) {
    const result = await this.consumeMagicLinkUseCase.execute(body);
    const value = unwrap(result);
    setWebSessionCookies(response, this.secure, value.tokens.token, value.tokens.refreshToken);
    return { user: value.user };
  }

  @PostAuth('web/session/refresh', {
    summary: 'Refresh web session',
    httpCode: HttpStatus.OK,
  })
  @AllowTokenTypes(JwtTokenType.REFRESH)
  @WebCookieAuth()
  @StrictOrigin()
  async refreshWebSession(@CurrentUser() user: AuthUser, @Res({ passthrough: true }) response: Response) {
    const result = await this.refreshWebSessionUseCase.execute(user);
    const value = unwrap(result);
    setWebSessionCookies(response, this.secure, value.token, value.refreshToken);
    return { refreshed: true };
  }

  @PostPublic('web/password-reset/request', {
    summary: 'Request a web password-reset email',
    bodyType: RequestWebPasswordResetDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 15, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async requestWebPasswordReset(@Body() body: RequestWebPasswordResetDTO) {
    unwrap(await this.requestWebPasswordResetUseCase.execute(body));
    return { sent: true };
  }

  @PostPublic('web/password-reset/consume', {
    summary: 'Set a password using a web-only recovery link',
    bodyType: ResetWebPasswordDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 10, ttl: THROTTLE_TTL_MINUTE_MS }, medium: { limit: 30, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @StrictOrigin()
  async resetWebPassword(@Body() body: ResetWebPasswordDTO) {
    unwrap(await this.resetWebPasswordUseCase.execute(body));
    return { reset: true };
  }

  @PostAuth('web/session/access-token', {
    summary: 'Read the current web access token for in-memory browser use',
    httpCode: HttpStatus.OK,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  @WebCookieAuth()
  @StrictOrigin()
  async getWebAccessToken(@Request() req: ExpressRequest & { user: AuthUser }, @Res({ passthrough: true }) response: Response) {
    response.setHeader('Cache-Control', 'no-store');
    const token = getWebSessionCookie(req.headers.cookie, WEB_ACCESS_COOKIE);
    if (!token) throw new UnauthorizedException('Cookie de sessão não fornecido');
    return { token };
  }

  @PostAuth('web/session/logout', {
    summary: 'Logout web session',
    responseType: MessageResponse,
  })
  @AllowTokenTypes(JwtTokenType.ACCESS)
  @WebCookieAuth()
  @StrictOrigin()
  async logoutWebSession(@Request() req: ExpressRequest & { user: AuthUser }, @Res({ passthrough: true }) response: Response) {
    const refreshPayload = ownedPayload(this.jwtService, getWebSessionCookie(req.headers.cookie, WEB_REFRESH_COOKIE), JwtTokenType.REFRESH, req.user.userId);
    const result = await this.logoutWebSessionUseCase.execute([req.user, refreshPayload]);
    unwrap(result);
    clearWebSessionCookies(response, this.secure);
    return result;
  }
}
