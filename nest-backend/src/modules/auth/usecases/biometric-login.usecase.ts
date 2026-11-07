import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AccountSuspendedError, AppError, InvalidCredentialsError, UnauthorizedError, UserNotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { BiometricLoginDTO } from '../dtos/auth.dto';
import { BiometricSessionResponse } from '../dtos/auth-response.class';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { BiometricCredentialService, BiometricChallengePurpose } from '@/shared/auth/biometric-credential.service';

@Injectable()
export class BiometricLoginUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly validator: JwtTokenValidatorService,
    private readonly credentials: BiometricCredentialService,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(input: BiometricLoginDTO): Promise<Either<AppError, BiometricSessionResponse>> {
    let payload: AuthUser;
    try {
      payload = await this.validator.verifyAndValidate<AuthUser>(input.biometricToken, [JwtTokenType.BIOMETRIC]);
    } catch {
      return left(new InvalidCredentialsError());
    }
    if (!payload.jti || !payload.exp || !payload.sid || !payload.userId) return left(new InvalidCredentialsError());

    const proofValid = await this.credentials.verifyAndConsume(payload, input.challengeId, input.signature, { purpose: BiometricChallengePurpose.LOGIN });
    if (!proofValid) return left(new InvalidCredentialsError());

    const userResult = await this.users.findById(payload.userId);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;
    if (!user) return left(new UserNotFoundError());
    if (user.suspendedAt) return left(new AccountSuspendedError(user.suspensionReason));

    if (!await this.sessionTokens.claimBiometric(payload.jti, payload.exp, payload.sid)) {
      return left(new UnauthorizedError('Token biométrico inválido ou já utilizado'));
    }
    const sessionStartedAtMs = payload.sessionStartedAtMs;
    if (typeof sessionStartedAtMs !== 'number' || !Number.isSafeInteger(sessionStartedAtMs)) return left(new InvalidCredentialsError());
    const session = issueSession(user, this.sessionTokens, sessionStartedAtMs, null, payload.sid);
    if (session.isLeft()) return left(session.value);
    return right({ ...session.value, biometricToken: this.sessionTokens.generateBiometric(user.id, user.role, payload.sid, sessionStartedAtMs) });
  }
}
