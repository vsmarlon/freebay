import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GuestUseCase } from './usecases/guest.usecase';
import { RegisterDTO, LoginDTO } from './dtos/auth.dto';
import {
  RequestPasswordRecoveryDTO,
  VerifyPasswordRecoveryCodeDTO,
  ResetPasswordDTO,
} from './dtos/password-recovery.dto';
import {
  AuthSessionResponse,
  GuestSessionResponse,
  TokenRefreshResponse,
  MessageResponse,
  StatusResponse,
} from './dtos/auth-response.class';
import { Public } from '@/shared/decorators/public.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthUser } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { AllowTokenTypes } from './guards/token-types.decorator';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly guestUseCase: GuestUseCase,
    private readonly requestPasswordRecoveryUseCase: RequestPasswordRecoveryUseCase,
    private readonly verifyPasswordRecoveryCodeUseCase: VerifyPasswordRecoveryCodeUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } })
  @ApiDoc({
    summary: 'Register new user',
    description: 'Creates account and returns JWT access + refresh tokens',
    bodyType: RegisterDTO,
    responseType: AuthSessionResponse,
    responseStatus: 201,
    errors: [{ status: 409, description: 'Email already exists' }],
  })
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
      { userId: user.id, role: user.role, type: 'access', jti: accessJti },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId: user.id, role: user.role, type: 'refresh', jti: refreshJti },
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );
    return result.isRight()
      ? { user, token, refreshToken }
      : left(new AppError('UNEXPECTED_ERROR', 'Erro inesperado'));
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: 10, ttl: 60000 }, medium: { limit: 30, ttl: 60000 } })
  @ApiDoc({
    summary: 'Login',
    description: 'Authenticate with email and password',
    bodyType: LoginDTO,
    responseType: AuthSessionResponse,
    errors: [{ status: 401, description: 'Invalid credentials' }],
  })
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
      { userId: user.id, role: user.role, type: 'access', jti: accessJti },
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId: user.id, role: user.role, type: 'refresh', jti: refreshJti },
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );

    return { user, token, refreshToken };
  }

  @Post('guest')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: 5, ttl: 60000 }, medium: { limit: 20, ttl: 60000 } })
  @ApiDoc({
    summary: 'Create guest session',
    description: 'Creates temporary guest user and returns JWT token',
    responseType: GuestSessionResponse,
  })
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Refresh token',
    description: 'Exchanges a valid refresh token for a new access + refresh token pair',
    auth: true,
    responseType: TokenRefreshResponse,
  })
  @AllowTokenTypes('refresh')
  async refresh(@CurrentUser() user: AuthUser) {
    if (user.type !== 'refresh') {
      return left(new AppError('INVALID_TOKEN', 'Token inválido: esperado token de refresh'));
    }

    await this.blacklistToken(user.jti, user.exp);

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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Logout',
    description: 'Blacklists current JWT tokens',
    auth: true,
    responseType: MessageResponse,
  })
  async logout(@CurrentUser() user: AuthUser, @Body() body?: { refreshToken?: string }) {
    await this.blacklistToken(user.jti, user.exp);

    if (body?.refreshToken) {
      try {
        const refreshPayload = await this.jwtService.verifyAsync<AuthUser>(body.refreshToken, {
          secret: this.config.getOrThrow('JWT_SECRET'),
        });

        if (refreshPayload.type === 'refresh' && refreshPayload.userId === user.userId) {
          await this.blacklistToken(refreshPayload.jti, refreshPayload.exp);
        }
      } catch {
        // Best effort only. Client token may already be expired or invalid.
      }
    }

    return { message: 'Logout realizado' };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Request password recovery',
    description: 'Sends password recovery code to the given email',
    bodyType: RequestPasswordRecoveryDTO,
  })
  @Public()
  async forgotPassword(@Body() body: RequestPasswordRecoveryDTO) {
    const result = await this.requestPasswordRecoveryUseCase.execute(body);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    return result.isRight() ? { sent: true } : left(new AppError('UNEXPECTED_ERROR', 'Erro inesperado'));
  }

  @Post('verify-reset-code')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Verify password recovery code',
    description: 'Checks if the 6-digit recovery code is valid',
    bodyType: VerifyPasswordRecoveryCodeDTO,
  })
  @Public()
  async verifyResetCode(@Body() body: VerifyPasswordRecoveryCodeDTO) {
    const result = await this.verifyPasswordRecoveryCodeUseCase.execute(body);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    return { verified: true };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Reset password',
    description: 'Resets password using verified recovery code',
    bodyType: ResetPasswordDTO,
  })
  @Public()
  async resetPassword(@Body() body: ResetPasswordDTO) {
    const result = await this.resetPasswordUseCase.execute(body);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    return { reset: true };
  }

  private async blacklistToken(jti?: string, exp?: number) {
    if (!jti || !exp) {
      return;
    }

    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) {
      await this.redisService.add(`blacklist:${jti}`, '1', ttl);
    }
  }
}
