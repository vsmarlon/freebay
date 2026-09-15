import {
  Injectable,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
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
import { UserDatabaseRepository } from './data/repositories/user-database.repository';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { RequestMagicLinkInput, RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
import { SessionTokenService } from './services/session-token.service';

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
    private readonly sessionTokens: SessionTokenService,
    private readonly requestMagicLinkUseCase: RequestMagicLinkUseCase,
    private readonly consumeMagicLinkUseCase: ConsumeMagicLinkUseCase,
    private readonly refreshWebSessionUseCase: RefreshWebSessionUseCase,
    private readonly logoutWebSessionUseCase: LogoutWebSessionUseCase,
  ) {}

  async register(input: RegisterDTO) {
    try {
      const result = await this.registerUseCase.execute(input);
      if (result.isLeft()) throw result.value;

      const { user } = result.value;
      this._assertNotSuspended(user);
      const tokens = this.sessionTokens.generate(user.id, user.role);
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
      const tokens = this.sessionTokens.generate(user.id, user.role);
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
      if (existingUser.isLeft() || !existingUser.value) {
        throw new UserNotFoundError('Usuário não encontrado');
      }

      this._assertNotSuspended(existingUser.value);

      if (!user.jti || !user.exp || !await this.sessionTokens.claimRefresh(user.jti, user.exp)) {
        throw new InvalidTokenError('Sessão já renovada');
      }
      await this.sessionTokens.revoke(user.jti, user.exp);
      const generated = this.sessionTokens.generate(existingUser.value.id, existingUser.value.role);

      return { token: generated.token, refreshToken: generated.refreshToken };
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
      await this.sessionTokens.revoke(user.jti, user.exp);

      if (refreshTokenPayload) {
        await this.sessionTokens.revoke(refreshTokenPayload.jti, refreshTokenPayload.exp);
      }

      if (biometricTokenPayload) {
        await this.sessionTokens.revoke(biometricTokenPayload.jti, biometricTokenPayload.exp);
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
      const result = await this.biometricLoginUseCase.execute(biometricToken);
      if (result.isLeft()) throw result.value;

      const { user, jti, exp } = result.value;
      this._assertNotSuspended(user);
      const tokens = this.sessionTokens.generate(user.id, user.role);
      const replacementBiometricToken = this.sessionTokens.generateBiometric(user.id, user.role);
      if (!await this.sessionTokens.claimBiometric(jti, exp)) {
        throw new UnauthorizedError('Token biométrico inválido ou já utilizado');
      }

      return {
        user,
        ...tokens,
        biometricToken: replacementBiometricToken,
      };
    } catch (err) {
      if (err instanceof AppError) throw err;
      this.logger.error(err);
      throw new InternalServerError('Erro interno ao fazer login biométrico');
    }
  }

  async revokeBiometricToken(jti?: string, exp?: number) {
    try {
      await this.sessionTokens.revoke(jti, exp);
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
      const tokens = this.sessionTokens.generate(user.id, user.role);
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

  async enrollBiometricToken(user: JwtPayload) {
    const now = Math.floor(Date.now() / 1000);
    if (
      !user.userId ||
      !user.role ||
      user.type !== JwtTokenType.ACCESS ||
      !user.jti ||
      user.iat === undefined ||
      user.iat > now ||
      now - user.iat > 300
    ) {
      throw new UnauthorizedError('Autenticação recente necessária');
    }
    if (!await this.sessionTokens.claimBiometricEnrollment(user.jti, user.exp)) {
      throw new UnauthorizedError('Sessão já utilizada para habilitar biometria');
    }
    return { biometricToken: this.sessionTokens.generateBiometric(user.userId, user.role) };
  }

  async requestMagicLink(input: RequestMagicLinkInput) {
    const result = await this.requestMagicLinkUseCase.execute(input);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  async consumeMagicLink(input: import('./dtos/magic-link.dto').ConsumeMagicLinkDTO) {
    const result = await this.consumeMagicLinkUseCase.execute(input);
    if (result.isLeft()) throw result.value;
    this._assertNotSuspended(result.value.user);
    const tokens = this.sessionTokens.generate(result.value.user.id, result.value.user.role);
    return { user: result.value.user, tokens };
  }

  async refreshWebSession(user: JwtPayload) {
    const result = await this.refreshWebSessionUseCase.execute(user);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  async logoutWebSession(payloads: Array<JwtPayload | undefined>) {
    const result = await this.logoutWebSessionUseCase.execute(payloads);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  private _assertNotSuspended(user: { suspendedAt?: Date | null; suspensionReason?: string | null }) {
    if (user.suspendedAt) {
      throw new AccountSuspendedError(user.suspensionReason ?? null);
    }
  }

}
