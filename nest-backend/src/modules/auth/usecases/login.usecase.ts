import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left } from '@/shared/core/either';
import { AppError, InvalidCredentialsError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { LoginDTO } from '../dtos/auth.dto';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';

@Injectable()
export class LoginUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(input: LoginDTO): Promise<Either<AppError, AuthSessionResponse>> {
    const sessionStartedAtMs = Date.now();
    // Login aceita e-mail ou @username único (usernames são [a-z0-9_]; o @ é só prefixo de digitação).
    const identifier = input.email.trim().toLowerCase().replace(/^@+/, '');
    const userResult = identifier.includes('@')
      ? await this.userRepository.findByEmail(identifier)
      : await this.userRepository.findByUsername(identifier);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;

    if (!user) {
      return left(new InvalidCredentialsError());
    }

    if (!user.passwordHash) {
      return left(new InvalidCredentialsError());
    }

    const passwordMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!passwordMatch) {
      return left(new InvalidCredentialsError());
    }

    return issueSession(user, this.sessionTokens, sessionStartedAtMs);
  }
}
