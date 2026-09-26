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

function normalizeOrigin(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  try {
    return new URL(trimmed).origin;
  } catch {
    return null;
  }
}

function allowedOrigins(config: ConfigService): Set<string> {
  const raw =
    config.get<string>('ALLOWED_ORIGINS') ??
    config.get<string>('WEB_APP_URL') ??
    config.get<string>('WEB_ALLOWED_ORIGIN') ??
    'http://localhost:3000';
  const out = new Set<string>();
  for (const part of raw.split(',')) {
    const normalized = normalizeOrigin(part);
    if (normalized) out.add(normalized);
  }
  return out;
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

    if (!origin) {
      if (strict) throw new UnauthorizedException('Origem web não autorizada');
      return true;
    }

    const normalized = normalizeOrigin(origin);
    if (!normalized || !allowedOrigins(this.config).has(normalized)) {
      throw new UnauthorizedException('Origem web não autorizada');
    }
    return true;
  }
}
