import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { Either, left } from '@/shared/core/either';
import { AppError, InvalidGoogleTokenError, UnverifiedGoogleEmailError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { AuthResponse } from '../mappers/auth.mapper';
import { normalizeEmail } from '../utils/normalize-email';
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

function decodeUnverifiedAudience(idToken: string): string {
  try {
    const segment = idToken.split('.')[1] ?? '';
    const payload = JSON.parse(
      Buffer.from(segment, 'base64url').toString('utf8'),
    ) as { aud?: unknown; azp?: unknown };
    return `aud=${String(payload.aud)} azp=${String(payload.azp)}`;
  } catch {
    return 'aud=<indecifrável>';
  }
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

  async execute(idToken: string): Promise<Either<AppError, AuthResponse & { token: string; refreshToken: string }>> {
    let payload: GooglePayload;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.audiences.length === 1 ? this.audiences[0] : this.audiences,
      });
      payload = ticket.getPayload() as GooglePayload;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(
        `Falha na validação do token Google: ${message} (${decodeUnverifiedAudience(idToken)} <> [${this.audiences.join(', ')}])`,
      );
      return left(new InvalidGoogleTokenError('Token Google inválido ou expirado'));
    }

    if (!payload || !payload.email) {
      this.logger.warn(`Token Google válido mas sem e-mail retornado: sub=${payload?.sub}`);
      return left(new InvalidGoogleTokenError('Token Google sem email associado'));
    }

    const email = normalizeEmail(payload.email);
    // 1. Usuário Google já registrado anteriormente
    const byGoogleId = await this.userRepository.findByGoogleId(payload.sub);
    if (byGoogleId.isLeft()) return left(byGoogleId.value);
    if (byGoogleId.value) {
      this.logger.log(`Login Google bem-sucedido para usuário existente: ${byGoogleId.value.id} (${byGoogleId.value.email})`);
      return issueSession(byGoogleId.value, this.sessionTokens);
    }

    // 2. Usuário com mesmo e-mail já existe — vincular conta Google
    const byEmail = await this.userRepository.findByEmail(email);
    if (byEmail.isLeft()) return left(byEmail.value);
    if (byEmail.value) {
      if (payload.email_verified !== true) {
        this.logger.warn(`Recusando vínculo Google não verificado ao usuário existente: ${byEmail.value.id}`);
        return left(new UnverifiedGoogleEmailError());
      }

      this.logger.log(`Vinculando conta Google ao usuário existente: ${byEmail.value.id} (${payload.email})`);
      const updated = await this.userRepository.update(byEmail.value.id, {
        googleId: payload.sub,
        emailVerified: true,
        avatarUrl: byEmail.value.avatarUrl ?? payload.picture ?? null,
      });
      if (updated.isLeft()) {
        this.logger.error(`Erro ao atualizar vínculo Google do usuário: ${updated.value.message}`);
        return left(updated.value);
      }
      return issueSession(updated.value, this.sessionTokens);
    }

    // 3. Novo usuário — criado inicialmente sem username (completará no frontend)
    this.logger.log(`Criando novo usuário via Google OAuth: ${payload.email}`);
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
      this.logger.error(`Erro ao criar novo usuário no banco: ${created.value.message}`);
      return left(created.value);
    }

    this.logger.log(`Novo usuário criado com sucesso: ${created.value.id} (${created.value.email})`);
    return issueSession(created.value, this.sessionTokens);
  }
}
