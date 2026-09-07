import {
  Injectable,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { CheckUsernameAvailabilityUseCase } from './usecases/check-username-availability.usecase';
import { BiometricLoginUseCase } from './usecases/biometric-login.usecase';
import { GoogleAuthUseCase } from './usecases/google-auth.usecase';
import { CompleteProfileUseCase } from './usecases/complete-profile.usecase';
import { CompleteProfileDTO } from './dtos/auth.dto';
import { RegisterDTO, LoginDTO, UsernameAvailabilityQueryDTO } from './dtos/auth.dto';
import {
  RequestPasswordRecoveryDTO,
  VerifyPasswordRecoveryCodeDTO,
  ResetPasswordDTO,
} from './dtos/password-recovery.dto';
import {
  AccountSuspendedError,
  AppError,
  InternalServerError,
  InvalidTokenError,
  UnauthorizedError,
  UserNotFoundError,
} from '@/shared/core/errors';
import { isLeft } from '@/shared/core/either';
import { UserDatabaseRepository } from './data/repositories/user-database.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly registerUseCase: RegisterUseCase,
    private readonly loginUseCase: LoginUseCase,
    private readonly requestPasswordRecoveryUseCase: RequestPasswordRecoveryUseCase,
    private readonly verifyPasswordRecoveryCodeUseCase: VerifyPasswordRecoveryCodeUseCase,
    private readonly resetPasswordUseCase: ResetPasswordUseCase,
    private readonly checkUsernameAvailabilityUseCase: CheckUsernameAvailabilityUseCase,
    private readonly biometricLoginUseCase: BiometricLoginUseCase,
    private readonly googleAuthUseCase: GoogleAuthUseCase,
    private readonly completeProfileUseCase: CompleteProfileUseCase,
    private readonly userRepository: UserDatabaseRepository,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  async register(input: RegisterDTO) {
    try {
      const result = await this.registerUseCase.execute(input);
      if (result.isLeft()) throw result.value;

      const { user } = result.value;
      this._assertNotSuspended(user);
      const tokens = this._generateSessionTokens(user.id, user.role);
      return { user, ...tokens };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao registrar');
    }
  }

  async login(input: LoginDTO) {
    try {
      const result = await this.loginUseCase.execute(input);
      if (result.isLeft()) throw result.value;

      const { user } = result.value;
      this._assertNotSuspended(user);
      const tokens = this._generateSessionTokens(user.id, user.role);
      return { user, ...tokens };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao logar');
    }
  }

  async refresh(user: { userId?: string; jti?: string; exp?: number; role?: string; type?: string }) {
    try {
      if (user.type !== JwtTokenType.REFRESH) {
        throw new InvalidTokenError('Token inválido: esperado token de refresh');
      }

      if (!user.userId) {
        throw new UnauthorizedError('Token inválido');
      }

      const existingUser = await this.userRepository.findById(user.userId);
      if (isLeft(existingUser) || !existingUser.value) {
        throw new UserNotFoundError('Usuário não encontrado');
      }

      this._assertNotSuspended(existingUser.value);

      await this.blacklistToken(user.jti, user.exp);

      const token = this.jwtService.sign(
        { userId: existingUser.value.id, role: existingUser.value.role, type: JwtTokenType.ACCESS, jti: randomUUID() } as JwtPayload,
        { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
      );
      const refreshToken = this.jwtService.sign(
        { userId: existingUser.value.id, role: existingUser.value.role, type: JwtTokenType.REFRESH, jti: randomUUID() } as JwtPayload,
        { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
      );

      return { token, refreshToken };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao renovar token');
    }
  }

  async logout(
    user: { jti?: string; exp?: number },
    refreshTokenPayload?: { jti?: string; exp?: number },
    biometricTokenPayload?: { jti?: string; exp?: number },
  ) {
    try {
      await this.blacklistToken(user.jti, user.exp);

      if (refreshTokenPayload) {
        await this.blacklistToken(refreshTokenPayload.jti, refreshTokenPayload.exp);
      }

      if (biometricTokenPayload) {
        await this.blacklistToken(biometricTokenPayload.jti, biometricTokenPayload.exp);
      }

      return { message: 'Logout realizado' };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao fazer logout');
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
      throw new InternalServerError('Erro interno ao solicitar recuperação');
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
      throw new InternalServerError('Erro interno ao verificar código');
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
      throw new InternalServerError('Erro interno ao redefinir senha');
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
      throw new InternalServerError('Erro interno ao verificar nome de usuário');
    }
  }

  async biometricLogin(biometricToken: string) {
    try {
      // Decode the incoming token to extract JTI for rotation (blacklist old token)
      let oldJti: string | undefined;
      let oldExp: number | undefined;
      try {
        const decoded = this.jwtService.decode<JwtPayload>(biometricToken);
        if (decoded?.type === JwtTokenType.BIOMETRIC) {
          oldJti = decoded.jti;
          oldExp = decoded.exp;
        }
      } catch { void 0; }

      const result = await this.biometricLoginUseCase.execute(biometricToken);
      if (result.isLeft()) throw result.value;

      const { user } = result.value;
      this._assertNotSuspended(user);
      const tokens = this._generateSessionTokens(user.id, user.role);

      // Rotate: blacklist the old biometric token now that a new one is issued
      await this.blacklistToken(oldJti, oldExp);

      return { user, ...tokens };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao fazer login biométrico');
    }
  }

  async revokeBiometricToken(jti?: string, exp?: number) {
    try {
      await this.blacklistToken(jti, exp);
      return { message: 'Token biométrico revogado' };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao revogar token biométrico');
    }
  }

  async googleAuth(idToken: string) {
    try {
      const result = await this.googleAuthUseCase.execute(idToken);
      if (result.isLeft()) throw result.value;

      const { user } = result.value;
      this._assertNotSuspended(user);
      const tokens = this._generateSessionTokens(user.id, user.role);
      return { user, ...tokens };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao autenticar com Google');
    }
  }

  async completeProfile(userId: string, input: CompleteProfileDTO) {
    try {
      const result = await this.completeProfileUseCase.execute(userId, input);
      if (result.isLeft()) throw result.value;
      return result.value;
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao completar perfil');
    }
  }

  private async blacklistToken(jti?: string, exp?: number) {
    if (!jti || !exp) return;
    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) {
      await this.redisService.add(`blacklist:${jti}`, '1', ttl);
    }
  }

  private _assertNotSuspended(user: { suspendedAt?: Date | null; suspensionReason?: string | null }) {
    if (user.suspendedAt) {
      throw new AccountSuspendedError(user.suspensionReason ?? null);
    }
  }

  private _generateSessionTokens(userId: string, role: string) {
    const accessJti = randomUUID();
    const refreshJti = randomUUID();
    const biometricJti = randomUUID();

    const token = this.jwtService.sign(
      { userId, role, type: JwtTokenType.ACCESS, jti: accessJti } as JwtPayload,
      { expiresIn: this.config.get('JWT_EXPIRES_IN', '15m') },
    );
    const refreshToken = this.jwtService.sign(
      { userId, role, type: JwtTokenType.REFRESH, jti: refreshJti } as JwtPayload,
      { expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d') },
    );
    const biometricToken = this.jwtService.sign(
      { userId, role, type: JwtTokenType.BIOMETRIC, jti: biometricJti } as JwtPayload,
      { expiresIn: this.config.get('JWT_BIOMETRIC_EXPIRES_IN', '7d') },
    );

    return { token, refreshToken, biometricToken };
  }
}
