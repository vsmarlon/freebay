import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { Either, left } from '@/shared/core/either';
import { AppError, EmailVerificationRequiredError, InvalidGoogleTokenError, UnverifiedGoogleEmailError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { normalizeEmail } from '@/shared/utils/normalize-email';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';
import { UserRole } from '@prisma/client';

interface GooglePayload {
  sub: string;
  email: string;
  name?: string;
  picture?: string;
  email_verified?: boolean;
}

@Injectable()
export class GoogleAuthUseCase {
  private readonly logger = new Logger(GoogleAuthUseCase.name);
  private readonly client: OAuth2Client;
  private readonly audiences: string[];

  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly config: ConfigService,
    private readonly sessionTokens: SessionTokenService,
  ) {
    this.audiences = [
      this.config.get<string>('GOOGLE_CLIENT_ID'),
      this.config.get<string>('GOOGLE_SERVER_CLIENT_ID'),
      this.config.get<string>('GOOGLE_WEB_CLIENT_ID'),
    ]
      .filter((id): id is string => Boolean(id && id.trim().length > 0))
      .flatMap((id) => id.split(',').map((s) => s.trim()))
      .filter((id) => id.length > 0);

    if (this.audiences.length === 0) {
      throw new Error(
        'GOOGLE_CLIENT_ID ou GOOGLE_SERVER_CLIENT_ID precisa estar definido: sem audience o token Google seria aceito de qualquer cliente OAuth',
      );
    }

    this.client = new OAuth2Client(this.audiences[0]);
  }

  async execute(idToken: string): Promise<Either<AppError, AuthSessionResponse>> {
    const sessionStartedAtMs = Date.now();
    let payload: GooglePayload;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.audiences.length === 1 ? this.audiences[0] : this.audiences,
      });
      payload = ticket.getPayload() as GooglePayload;
    } catch {
      this.logger.error('Falha na validação do token Google');
      return left(new InvalidGoogleTokenError('Token Google inválido ou expirado'));
    }

    if (!payload || !payload.email) {
      this.logger.warn('Token Google válido sem e-mail retornado');
      return left(new InvalidGoogleTokenError('Token Google sem email associado'));
    }

    const email = normalizeEmail(payload.email);
    // 1. Usuário Google já registrado anteriormente
    const byGoogleId = await this.userRepository.findByGoogleId(payload.sub);
    if (byGoogleId.isLeft()) return left(byGoogleId.value);
    if (byGoogleId.value) {
      this.logger.log('Login Google bem-sucedido para usuário existente');
      return issueSession(byGoogleId.value, this.sessionTokens, sessionStartedAtMs);
    }

    // 2. Usuário com mesmo e-mail já existe — vincular conta Google
    const byEmail = await this.userRepository.findByEmail(email);
    if (byEmail.isLeft()) return left(byEmail.value);
    if (byEmail.value) {
      if (payload.email_verified !== true) {
          this.logger.warn('Recusando vínculo Google não verificado');
        return left(new UnverifiedGoogleEmailError());
      }
      if (byEmail.value.emailVerified !== true) {
        this.logger.warn('Recusando vínculo Google: conta local sem e-mail verificado');
        return left(new EmailVerificationRequiredError('Verifique seu e-mail antes de vincular sua conta Google'));
      }

      this.logger.log('Vinculando conta Google ao usuário existente');
      const updated = await this.userRepository.update(byEmail.value.id, {
        googleId: payload.sub,
        avatarUrl: byEmail.value.avatarUrl ?? payload.picture ?? null,
      });
      if (updated.isLeft()) {
        this.logger.error('Erro ao atualizar vínculo Google');
        return left(updated.value);
      }
      return issueSession(updated.value, this.sessionTokens, sessionStartedAtMs);
    }

    // 3. Novo usuário — criado inicialmente sem username (completará no frontend)
    this.logger.log('Criando novo usuário via Google OAuth');
    const created = await this.userRepository.create({
      displayName: payload.name ?? payload.email.split('@')[0],
      username: null,
       email,
      passwordHash: null,
      googleId: payload.sub,
      emailVerified: payload.email_verified === true,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: null,
      state: null,
      avatarUrl: payload.picture ?? null,
      bio: null,
      isVerified: false,
      isGuest: false,
      role: UserRole.USER,
      reputationScore: 0,
      totalReviews: 0,
      wallet: { create: {} },
    });
    if (created.isLeft()) {
      this.logger.error('Erro ao criar novo usuário Google');
      return left(created.value);
    }

    this.logger.log('Novo usuário criado com sucesso via Google');
    return issueSession(created.value, this.sessionTokens, sessionStartedAtMs);
  }

  async verifyForStepUp(idToken: string): Promise<{ subject: string } | null> {
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.audiences.length === 1 ? this.audiences[0] : this.audiences,
      });
      const subject = ticket.getPayload()?.sub;
      const issuedAt = decodeTokenIssuedAt(idToken);
      const now = Math.floor(Date.now() / 1000);
      return subject && issuedAt !== null && issuedAt <= now + 30 && now - issuedAt <= 300
        ? { subject }
        : null;
    } catch {
      return null;
    }
  }
}

function decodeTokenIssuedAt(idToken: string): number | null {
  try {
    const segment = idToken.split('.')[1];
    if (!segment) return null;
    const claims: unknown = JSON.parse(Buffer.from(segment, 'base64url').toString('utf8'));
    return isRecord(claims) && typeof claims.iat === 'number' ? claims.iat : null;
  } catch {
    return null;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
