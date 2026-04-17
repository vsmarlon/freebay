import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { IS_PUBLIC_KEY } from '@/shared/decorators/public.decorator';
import { JwtPayload } from '@/shared/core/types';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    @Inject(forwardRef(() => RedisService))
    private readonly redisService: RedisService,
    private readonly reflector: Reflector,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
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

    if (!token) {
      throw new UnauthorizedException('Token não fornecido');
    }

    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(token, {
        secret: this.config.get('JWT_SECRET', 'default-secret'),
      });

      const isBlacklisted = payload.jti
        ? await this.redisService.exists(`blacklist:${payload.jti}`)
        : false;

      if (isBlacklisted) {
        throw new UnauthorizedException('Token revogado');
      }

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
