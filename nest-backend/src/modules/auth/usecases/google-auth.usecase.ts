import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
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
  private readonly client: OAuth2Client;

  constructor(
    private readonly userRepository: UserRepository,
    private readonly config: ConfigService,
  ) {
    this.client = new OAuth2Client(this.config.get<string>('GOOGLE_CLIENT_ID'));
  }

  async execute(idToken: string): Promise<Either<AppError, AuthResponse>> {
    let payload: GooglePayload;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.config.get<string>('GOOGLE_CLIENT_ID'),
      });
      payload = ticket.getPayload() as GooglePayload;
    } catch {
      return left(new AppError('INVALID_GOOGLE_TOKEN', 'Token Google inválido', 401));
    }

    if (!payload.email) {
      return left(new AppError('INVALID_GOOGLE_TOKEN', 'Token Google sem email', 401));
    }

    // Returning Google user
    const byGoogleId = await this.userRepository.findByGoogleId(payload.sub);
    if (byGoogleId.isLeft()) return left(byGoogleId.value);
    if (byGoogleId.value) {
      return right(toAuthResponse(byGoogleId.value));
    }

    // Existing email user — link Google account
    const byEmail = await this.userRepository.findByEmail(payload.email);
    if (byEmail.isLeft()) return left(byEmail.value);
    if (byEmail.value) {
      const updated = await this.userRepository.update(byEmail.value.id, {
        googleId: payload.sub,
        emailVerified: payload.email_verified ?? true,
        avatarUrl: byEmail.value.avatarUrl ?? payload.picture ?? null,
      });
      if (updated.isLeft()) return left(updated.value);
      return right(toAuthResponse(updated.value));
    }

    // New user — no username yet, user completes profile on frontend
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
    if (created.isLeft()) return left(created.value);

    return right(toAuthResponse(created.value));
  }
}
