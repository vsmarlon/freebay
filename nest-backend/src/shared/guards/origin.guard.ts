import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { STRICT_ORIGIN_KEY } from '@/shared/decorators/strict-origin.decorator';
import { isAllowedOrigin, parseAllowedOrigins } from '@/shared/http/origin-policy';

function allowedOrigins(config: ConfigService): readonly string[] {
  const raw =
    config.get<string>('ALLOWED_ORIGINS') ??
    config.get<string>('WEB_APP_URL') ??
    config.get<string>('WEB_ALLOWED_ORIGIN') ??
    'http://localhost:3000';
  return parseAllowedOrigins(raw);
}

@Injectable()
export class OriginGuard implements CanActivate {
  constructor(
    private readonly config: ConfigService,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const origin = request.headers.origin;
    const strict = this.reflector.getAllAndOverride<boolean>(
      STRICT_ORIGIN_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!isAllowedOrigin(origin, allowedOrigins(this.config)) || (!origin && strict)) {
      throw new UnauthorizedException('Origem web não autorizada');
    }
    return true;
  }
}
