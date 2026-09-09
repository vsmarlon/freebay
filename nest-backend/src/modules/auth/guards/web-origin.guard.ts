import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';

@Injectable()
export class WebOriginGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const origin = context.switchToHttp().getRequest<Request>().headers.origin;
    const configured = this.config.get<string>('WEB_APP_URL') ?? this.config.get<string>('WEB_ALLOWED_ORIGIN');
    if (!origin || !configured) throw new UnauthorizedException('Origem web não autorizada');
    try {
      if (new URL(origin).origin !== new URL(configured).origin) throw new UnauthorizedException('Origem web não autorizada');
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Origem web não autorizada');
    }
    return true;
  }
}
