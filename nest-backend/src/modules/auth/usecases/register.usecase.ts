import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left } from '@/shared/core/either';
import { AppError, EmailAlreadyExistsError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { RegisterDTO } from '../dtos/auth.dto';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { normalizeEmail } from '../utils/normalize-email';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';
import { UserRole } from '@prisma/client';

@Injectable()
export class RegisterUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(input: RegisterDTO): Promise<Either<AppError, AuthSessionResponse>> {
    const email = normalizeEmail(input.email);
    const existingResult = await this.userRepository.findByEmail(email);
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) {
      return left(new EmailAlreadyExistsError());
    }

    const existingUsernameResult = await this.userRepository.findByUsername(input.username);
    if (existingUsernameResult.isLeft()) return left(existingUsernameResult.value);
    if (existingUsernameResult.value) {
      return left(new UsernameAlreadyExistsError());
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    const createResult = await this.userRepository.create({
      displayName: input.displayName,
      username: input.username,
      email,
      passwordHash,
      emailVerified: false,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: input.city ?? null,
      state: input.state ?? null,
      avatarUrl: null,
      bio: null,
      isVerified: false,
      isGuest: false,
      role: UserRole.USER,
      reputationScore: 0,
      totalReviews: 0,
    });
    if (createResult.isLeft()) return left(createResult.value);

    return issueSession(createResult.value, this.sessionTokens);
  }
}
