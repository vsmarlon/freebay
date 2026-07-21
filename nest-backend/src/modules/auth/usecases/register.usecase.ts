import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, EmailAlreadyExistsError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { UserRepository } from '../domain/repositories/user.repository';
import { RegisterDTO } from '../dtos/auth.dto';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

@Injectable()
export class RegisterUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: RegisterDTO): Promise<Either<AppError, AuthResponse>> {
    const existingResult = await this.userRepository.findByEmail(input.email);
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
      email: input.email,
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
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
    });
    if (createResult.isLeft()) return left(createResult.value);

    return right(toAuthResponse(createResult.value));
  }
}
