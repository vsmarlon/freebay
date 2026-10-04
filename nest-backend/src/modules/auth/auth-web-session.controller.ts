import {
  Controller,
  Body,
  Request,
  HttpStatus,
  Res,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
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
import { RequestMagicLinkDTO, ConsumeMagicLinkDTO } from './dtos/magic-link.dto';
import {
  getWebSessionCookie,
  WEB_REFRESH_COOKIE,
  ownedPayload,
  setWebSessionCookies,
  clearWebSessionCookies,
} from './utils/web-session-cookies';
import type { Request as ExpressRequest, Response } from 'express';
import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

function unwrap<T>(result: Either<AppError, T>): T {
  if (result.isLeft()) throw result.value;
  return result.value;
}

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
  ) {}

  private get secure(): boolean {
    return this.configService.get('NODE_ENV') === 'production';
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
