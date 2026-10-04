import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Either, left } from '@/shared/core/either';
import { AppleEmailCollisionError, AppError, AppleUnavailableError, InvalidAppleTokenError } from '@/shared/core/errors';
import { AppleConfigurationError, AppleProviderService } from '@/shared/auth/apple-provider.service';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { normalizeEmail } from '../utils/normalize-email';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';

@Injectable()
export class AppleAuthUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly apple: AppleProviderService,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(input: { identityToken: string; authorizationCode: string; rawNonce: string; fullName?: string }): Promise<Either<AppError, AuthSessionResponse>> {
    try {
      const clientIdentity = await this.apple.verifyIdentityToken(input.identityToken, input.rawNonce);
      const exchanged = await this.apple.exchangeAuthorizationCode(input.authorizationCode, input.rawNonce);
      if (clientIdentity.sub !== exchanged.identity.sub || clientIdentity.nonce !== exchanged.identity.nonce) {
        return left(new InvalidAppleTokenError('A resposta da Apple não corresponde ao login iniciado'));
      }

      const byAppleId = await this.users.findByAppleId(exchanged.identity.sub);
      if (byAppleId.isLeft()) return left(byAppleId.value);
      if (byAppleId.value) {
        if (byAppleId.value.deletedAt) return left(new InvalidAppleTokenError('Esta conta foi removida'));
        const updated = await this.users.updateAppleCredential(byAppleId.value.id, exchanged.encryptedRefreshToken);
        if (updated.isLeft()) return left(updated.value);
        if (!updated.value || updated.value.deletedAt) return left(new InvalidAppleTokenError('Esta conta foi removida'));
        return issueSession(updated.value, this.sessionTokens);
      }

      if (!exchanged.identity.email || exchanged.identity.emailVerified !== true) {
        return left(new InvalidAppleTokenError('A Apple precisa fornecer um e-mail verificado para criar a conta'));
      }
      const email = normalizeEmail(exchanged.identity.email);
      const byEmail = await this.users.findByEmail(email);
      if (byEmail.isLeft()) return left(byEmail.value);
      if (byEmail.value) return left(new AppleEmailCollisionError());

      const created = await this.users.create({
        displayName: input.fullName ?? email.split('@')[0],
        username: null,
        email,
        passwordHash: null,
        appleId: exchanged.identity.sub,
        appleRefreshTokenEncrypted: exchanged.encryptedRefreshToken,
        emailVerified: true,
        cpfHash: null,
        phone: null,
        phoneVerified: false,
        city: null,
        state: null,
        avatarUrl: null,
        bio: null,
        isVerified: false,
        isGuest: false,
        role: UserRole.USER,
        reputationScore: 0,
        totalReviews: 0,
        wallet: { create: {} },
      });
      if (created.isLeft()) return left(created.value);
      return issueSession(created.value, this.sessionTokens);
    } catch (error) {
      if (error instanceof AppleConfigurationError) return left(new AppleUnavailableError());
      return left(new InvalidAppleTokenError());
    }
  }
}
