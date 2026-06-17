import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '@/shared/decorators/public.decorator';
import { ALLOWED_TOKEN_TYPES_KEY } from './token-types.decorator';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';

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

    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    const allowedTokenTypes = this.reflector.getAllAndOverride<Array<'access' | 'refresh'>>(
      ALLOWED_TOKEN_TYPES_KEY,
      [context.getHandler(), context.getClass()],
    ) ?? ['access'];

    if (!token) {
      throw new UnauthorizedException('Token não fornecido');
    }

    try {
      const payload = await this.tokenValidator.verifyAndValidate(token, allowedTokenTypes);

      request.user = payload;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Token inválido');
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const headers = request.headers as unknown as Record<string, string | undefined>;
    const authHeader = headers.authorization;
    const [type, value] = authHeader?.split(' ') ?? [];
    return type === 'Bearer' ? value : undefined;
  }
}
