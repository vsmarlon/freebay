import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidGoogleTokenError } from '@/shared/core/errors';
import { UserRepository } from '../domain/repositories/user.repository';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

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

  constructor(
    private readonly userRepository: UserRepository,
    private readonly config: ConfigService,
  ) {
    const defaultClientId = this.config.get<string>('GOOGLE_CLIENT_ID') || this.config.get<string>('GOOGLE_SERVER_CLIENT_ID');
    this.client = new OAuth2Client(defaultClientId);
  }

  async execute(idToken: string): Promise<Either<AppError, AuthResponse>> {
    let payload: GooglePayload;
    try {
      const configuredAudiences = [
        this.config.get<string>('GOOGLE_CLIENT_ID'),
        this.config.get<string>('GOOGLE_SERVER_CLIENT_ID'),
      ]
        .filter((id): id is string => Boolean(id && id.trim().length > 0))
        .flatMap((id) => id.split(',').map((s) => s.trim()));

      const audienceParam = configuredAudiences.length === 1
        ? configuredAudiences[0]
        : configuredAudiences.length > 1
          ? configuredAudiences
          : undefined;

      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: audienceParam,
      });
      payload = ticket.getPayload() as GooglePayload;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`Falha na validação do token Google: ${message}`);
      return left(new InvalidGoogleTokenError('Token Google inválido ou expirado'));
    }

    if (!payload || !payload.email) {
      this.logger.warn(`Token Google válido mas sem e-mail retornado: sub=${payload?.sub}`);
      return left(new InvalidGoogleTokenError('Token Google sem email associado'));
    }

    // 1. Usuário Google já registrado anteriormente
    const byGoogleId = await this.userRepository.findByGoogleId(payload.sub);
    if (byGoogleId.isLeft()) return left(byGoogleId.value);
    if (byGoogleId.value) {
      this.logger.log(`Login Google bem-sucedido para usuário existente: ${byGoogleId.value.id} (${byGoogleId.value.email})`);
      return right(toAuthResponse(byGoogleId.value));
    }

    // 2. Usuário com mesmo e-mail já existe — vincular conta Google
    const byEmail = await this.userRepository.findByEmail(payload.email);
    if (byEmail.isLeft()) return left(byEmail.value);
    if (byEmail.value) {
      this.logger.log(`Vinculando conta Google ao usuário existente: ${byEmail.value.id} (${payload.email})`);
      const updated = await this.userRepository.update(byEmail.value.id, {
        googleId: payload.sub,
        emailVerified: payload.email_verified ?? true,
        avatarUrl: byEmail.value.avatarUrl ?? payload.picture ?? null,
      });
      if (updated.isLeft()) {
        this.logger.error(`Erro ao atualizar vínculo Google do usuário: ${updated.value.message}`);
        return left(updated.value);
      }
      return right(toAuthResponse(updated.value));
    }

    // 3. Novo usuário — criado inicialmente sem username (completará no frontend)
    this.logger.log(`Criando novo usuário via Google OAuth: ${payload.email}`);
    const created = await this.userRepository.create({
      displayName: payload.name ?? payload.email.split('@')[0],
      username: null,
      email: payload.email,
      passwordHash: null,
      googleId: payload.sub,
      emailVerified: payload.email_verified ?? true,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: null,
      state: null,
      avatarUrl: payload.picture ?? null,
      bio: null,
      isVerified: false,
      isGuest: false,
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
    });
    if (created.isLeft()) {
      this.logger.error(`Erro ao criar novo usuário no banco: ${created.value.message}`);
      return left(created.value);
    }

    this.logger.log(`Novo usuário criado com sucesso: ${created.value.id} (${created.value.email})`);
    return right(toAuthResponse(created.value));
  }
}
