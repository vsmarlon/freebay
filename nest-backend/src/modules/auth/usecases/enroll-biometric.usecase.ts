import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UnauthorizedError } from '@/shared/core/errors';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';

@Injectable()
export class EnrollBiometricUseCase {
  constructor(private readonly tokens: SessionTokenService) {}

  async execute(user: JwtPayload): Promise<Either<AppError, { biometricToken: string }>> {
    const now = Math.floor(Date.now() / 1000);
    if (!user.userId || !user.role || user.type !== JwtTokenType.ACCESS || !user.jti || user.iat === undefined || user.iat > now || now - user.iat > 300) {
      return left(new UnauthorizedError('Autenticação recente necessária'));
    }
    if (!await this.tokens.claimBiometricEnrollment(user.jti, user.exp)) {
      return left(new UnauthorizedError('Sessão já utilizada para habilitar biometria'));
    }
    return right({ biometricToken: this.tokens.generateBiometric(user.userId, user.role) });
  }
}
