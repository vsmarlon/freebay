import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UsePipes,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GuestUseCase } from './usecases/guest.usecase';
import { loginSchema, registerSchema, RegisterDTO, LoginDTO } from './dtos/auth.dto';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { Public } from '@/shared/decorators/public.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthUser } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly guestUseCase: GuestUseCase,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ZodValidationPipe(registerSchema))
  @Public()
  async register(@Body() body: RegisterDTO) {
    const result = await this.registerUseCase.execute(body);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    const { user } = result.value;
    const accessJti = randomUUID();
    const refreshJti = randomUUID();
    const token = this.jwtService.sign(
      { userId: user.id, role: 'USER', type: 'access', jti: accessJti },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId: user.id, role: 'USER', type: 'refresh', jti: refreshJti },
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );
    return result.isRight() 
      ? { user, token, refreshToken }
      : left(new AppError('UNEXPECTED_ERROR', 'Erro inesperado'));
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @UsePipes(new ZodValidationPipe(loginSchema))
  @Public()
  async login(@Body() body: LoginDTO) {
    const result = await this.loginUseCase.execute(body);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    const { user } = result.value;
    const accessJti = randomUUID();
    const refreshJti = randomUUID();
    const token = this.jwtService.sign(
      { userId: user.id, role: 'USER', type: 'access', jti: accessJti },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId: user.id, role: 'USER', type: 'refresh', jti: refreshJti },
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );

    return { user, token, refreshToken };
  }

  @Post('guest')
  @HttpCode(HttpStatus.OK)
  @Public()
  async guest() {
    const result = await this.guestUseCase.execute();

    const token = this.jwtService.sign(
      { isGuest: true, role: 'GUEST', type: 'access', jti: randomUUID() },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );

    return {
      user: { id: result.userId, isGuest: true },
      token,
    };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async refresh(@CurrentUser() user: AuthUser) {
    if (user.type !== 'refresh') {
      return left(new AppError('INVALID_TOKEN', 'Token inválido: esperado token de refresh'));
    }

    const token = this.jwtService.sign(
      { userId: user.userId, role: user.role, type: 'access', jti: randomUUID() },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId: user.userId, role: user.role, type: 'refresh', jti: randomUUID() },
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );

    return { token, refreshToken };
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async logout(@CurrentUser() user: AuthUser) {
    if (user.jti && user.exp) {
      const ttl = user.exp - Math.floor(Date.now() / 1000);
      if (ttl > 0) {
        await this.redisService.add(`blacklist:${user.jti}`, '1', ttl);
      }
    }

    return { message: 'Logout realizado' };
  }
}
