import {
  Injectable,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GuestUseCase } from './usecases/guest.usecase';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { CheckUsernameAvailabilityUseCase } from './usecases/check-username-availability.usecase';
import { RegisterDTO, LoginDTO, UsernameAvailabilityQueryDTO } from './dtos/auth.dto';
import {
  RequestPasswordRecoveryDTO,
  VerifyPasswordRecoveryCodeDTO,
  ResetPasswordDTO,
} from './dtos/password-recovery.dto';
import { AppError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly guestUseCase: GuestUseCase,
    private readonly requestPasswordRecoveryUseCase: RequestPasswordRecoveryUseCase,
    private readonly verifyPasswordRecoveryCodeUseCase: VerifyPasswordRecoveryCodeUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly checkUsernameAvailabilityUseCase: CheckUsernameAvailabilityUseCase,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  async register(input: RegisterDTO) {
    try {
      const result = await this.registerUseCase.execute(input);
      if (result.isLeft()) throw result.value;

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
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao registrar');
    }
  }

  async login(input: LoginDTO) {
    try {
      const result = await this.loginUseCase.execute(input);
      if (result.isLeft()) throw result.value;

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
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao logar');
    }
  }

  async guest() {
    try {
      const result = await this.guestUseCase.execute();
      if (result.isLeft()) throw result.value;

      const token = this.jwtService.sign(
        { isGuest: true, role: 'GUEST', type: 'access', jti: randomUUID() },
        { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
      );

      return { user: { id: result.value.userId, isGuest: true }, token };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao criar sessão convidado');
    }
  }

  async refresh(user: { userId?: string; jti?: string; exp?: number; role?: string; type?: string }) {
    try {
      if (user.type !== 'refresh') {
        throw new AppError('INVALID_TOKEN', 'Token inválido: esperado token de refresh');
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
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao renovar token');
    }
  }

  async logout(user: { jti?: string; exp?: number }, refreshTokenPayload?: { jti?: string; exp?: number }) {
    try {
      await this.blacklistToken(user.jti, user.exp);

      if (refreshTokenPayload) {
        await this.blacklistToken(refreshTokenPayload.jti, refreshTokenPayload.exp);
      }

      return { message: 'Logout realizado' };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao fazer logout');
    }
  }

  async forgotPassword(input: RequestPasswordRecoveryDTO) {
    try {
      const result = await this.requestPasswordRecoveryUseCase.execute(input);
      if (result.isLeft()) throw result.value;
      return { sent: true };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao solicitar recuperação');
    }
  }

  async verifyResetCode(input: VerifyPasswordRecoveryCodeDTO) {
    try {
      const result = await this.verifyPasswordRecoveryCodeUseCase.execute(input);
      if (result.isLeft()) throw result.value;
      return { verified: true };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao verificar código');
    }
  }

  async resetPassword(input: ResetPasswordDTO) {
    try {
      const result = await this.resetPasswordUseCase.execute(input);
      if (result.isLeft()) throw result.value;
      return { reset: true };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao redefinir senha');
    }
  }

  async checkUsernameAvailability(input: UsernameAvailabilityQueryDTO) {
    try {
      const result = await this.checkUsernameAvailabilityUseCase.execute({ username: input.u });
      if (result.isLeft()) throw result.value;
      return result.value;
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new AppError('INTERNAL_ERROR', 'Erro interno ao verificar nome de usuário');
    }
  }

  private async blacklistToken(jti?: string, exp?: number) {
    if (!jti || !exp) return;
    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) {
      await this.redisService.add(`blacklist:${jti}`, '1', ttl);
    }
  }
}
