import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { AppError, InvalidCredentialsError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { UserDatabaseRepository } from '@/modules/users';
import { StepUpDTO } from '../dtos/auth.dto';
import { StepUpService } from '@/shared/auth/step-up.service';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { AppleProviderService } from '@/shared/auth/apple-provider.service';
import { GoogleAuthUseCase } from './google-auth.usecase';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { isValidStepUpResource, verifyStepUpMagicContext } from '../utils/step-up-magic-context';

export type CreateStepUpOptions = { web?: boolean };

@Injectable()
export class CreateStepUpUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly google: GoogleAuthUseCase,
    private readonly stepUp: StepUpService,
    private readonly credentials: BiometricCredentialService,
    private readonly validator: JwtTokenValidatorService,
    private readonly apple: AppleProviderService,
    private readonly magicLinks: MagicLinkRepository,
    private readonly config: ConfigService,
  ) {}

  async execute(user: AuthUser, input: StepUpDTO, options: CreateStepUpOptions = {}): Promise<Either<AppError, { stepUpToken: string; expiresAt: string }>> {
    if (!isValidStepUpResource(input.purpose, input.resourceId)) return left(new InvalidCredentialsError());
    const proof = await this.verifyProof(user, input, options.web === true);
    if (proof.isLeft()) return left(proof.value);
    return right(await this.stepUp.issue(user.userId, input.purpose, input.resourceId));
  }

  private async verifyProof(user: AuthUser, input: StepUpDTO, web: boolean): Promise<Either<AppError, void>> {
    const proof = input.proof;
    if (!onlyKeys(proof, proof.kind)) return left(new InvalidCredentialsError());

    if (proof.kind === 'password' && proof.password) {
      const found = await this.users.findById(user.userId);
      if (found.isLeft()) return left(found.value);
      return found.value?.passwordHash && await bcrypt.compare(proof.password, found.value.passwordHash)
        ? right(undefined) : left(new InvalidCredentialsError());
    }

    if (proof.kind === 'google' && proof.idToken) return this.verifyGoogle(user.userId, proof.idToken);
    if (proof.kind === 'apple' && proof.identityToken && proof.rawNonce) return this.verifyApple(user.userId, proof.identityToken, proof.rawNonce, web);
    if (proof.kind === 'magic_link' && proof.token && proof.contextSignature && web) {
      return this.verifyMagicLink(user, input, proof.token, proof.contextSignature);
    }
    if (proof.kind === 'biometric' && proof.biometricToken && proof.challengeId && proof.signature) {
      let token: AuthUser;
      try {
        token = await this.validator.verifyAndValidate<AuthUser>(proof.biometricToken, [JwtTokenType.BIOMETRIC]);
      } catch {
        return left(new InvalidCredentialsError());
      }
      const verified = await this.credentials.verifyAndConsume(token, proof.challengeId, proof.signature, {
        purpose: 'step_up', stepUpPurpose: input.purpose, ...(input.resourceId ? { resourceId: input.resourceId } : {}),
      });
      return token.userId === user.userId && verified ? right(undefined) : left(new InvalidCredentialsError());
    }
    return left(new InvalidCredentialsError());
  }

  private async verifyGoogle(userId: string, idToken: string): Promise<Either<AppError, void>> {
    const identity = await this.google.verifyForStepUp(idToken);
    if (!identity) return left(new InvalidCredentialsError());
    const found = await this.users.findByGoogleId(identity.subject);
    if (found.isLeft()) return left(found.value);
    return found.value?.id === userId ? right(undefined) : left(new InvalidCredentialsError());
  }

  private async verifyApple(userId: string, identityToken: string, rawNonce: string, web: boolean): Promise<Either<AppError, void>> {
    try {
      const identity = web
        ? await this.apple.verifyIdentityToken(identityToken, rawNonce, this.config.getOrThrow<string>('APPLE_WEB_CLIENT_ID'))
        : await this.apple.verifyIdentityToken(identityToken, rawNonce);
      const claims = decodeClaims(identityToken);
      if (!claims || !isRecent(claims.iat)) return left(new InvalidCredentialsError());
      const found = await this.users.findByAppleId(identity.sub);
      if (found.isLeft()) return left(found.value);
      return found.value?.id === userId ? right(undefined) : left(new InvalidCredentialsError());
    } catch {
      return left(new InvalidCredentialsError());
    }
  }

  private async verifyMagicLink(
    user: AuthUser,
    input: StepUpDTO,
    token: string,
    contextSignature: string,
  ): Promise<Either<AppError, void>> {
    if (!token.startsWith('stepup.') || typeof user.sessionStartedAtMs !== 'number') return left(new InvalidCredentialsError());
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const validContext = verifyStepUpMagicContext(this.config.getOrThrow<string>('JWT_SECRET'), {
      userId: user.userId,
      purpose: input.purpose,
      resourceId: input.resourceId,
      tokenHash,
    }, contextSignature);
    if (!validContext) return left(new InvalidCredentialsError());

    const consumed = await this.magicLinks.consumeStepUpProof(tokenHash, user.userId, user.sessionStartedAtMs, new Date());
    if (consumed.isLeft()) return left(consumed.value);
    return consumed.value ? right(undefined) : left(new InvalidCredentialsError());
  }
}

function onlyKeys(proof: StepUpDTO['proof'], kind: StepUpDTO['proof']['kind']): boolean {
  const allowed = kind === 'password' ? ['kind', 'password']
    : kind === 'google' ? ['kind', 'idToken']
      : kind === 'apple' ? ['kind', 'identityToken', 'rawNonce']
        : kind === 'magic_link' ? ['kind', 'token', 'contextSignature']
        : ['kind', 'biometricToken', 'challengeId', 'signature'];
  return Object.keys(proof).every((key) => allowed.includes(key));
}

function decodeClaims(token: string): Record<string, unknown> | null {
  try {
    const segment = token.split('.')[1];
    if (!segment) return null;
    const value: unknown = JSON.parse(Buffer.from(segment, 'base64url').toString('utf8'));
    return isRecord(value) ? value : null;
  } catch {
    return null;
  }
}

function isRecent(iat: unknown): boolean {
  const now = Math.floor(Date.now() / 1000);
  return typeof iat === 'number' && iat <= now + 30 && now - iat <= 300;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
