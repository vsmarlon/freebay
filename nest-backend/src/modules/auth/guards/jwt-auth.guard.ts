import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '@/shared/decorators';
import { ALLOWED_TOKEN_TYPES_KEY } from './token-types.decorator';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';

import { Request } from 'express';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokenValidator: JwtTokenValidatorService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractTokenFromHeader(request);
    const allowedTokenTypes = this.reflector.getAllAndOverride<Array<JwtTokenType>>(
      ALLOWED_TOKEN_TYPES_KEY,
      [context.getHandler(), context.getClass()],
    ) ?? [JwtTokenType.ACCESS];

    if (!token) {
      throw new UnauthorizedException('Token não fornecido');
    }

    try {
      const payload = await this.tokenValidator.verifyAndValidate(token, allowedTokenTypes);

      (request as Request & { user: unknown }).user = payload;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Token inválido');
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const authHeader = request.headers.authorization;
    const [type, value] = authHeader?.split(' ') ?? [];
    return type === 'Bearer' ? value : undefined;
  }
}
