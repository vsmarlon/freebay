import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { JwtPayload } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';

@Injectable()
export class LogoutWebSessionUseCase {
  constructor(private readonly tokens: SessionTokenService) {}

  async execute(payloads: Array<JwtPayload | undefined>): Promise<Either<AppError, { message: string }>> {
    const families = [...new Set(payloads.flatMap((payload) => payload?.sid ? [payload.sid] : []))];
    await Promise.all([
      ...payloads.map((payload) => this.tokens.revoke(payload?.jti, payload?.exp)),
      ...families.map((sid) => this.tokens.revokeFamily(sid)),
    ]);
    return right({ message: 'Logout realizado' });
  }
}
