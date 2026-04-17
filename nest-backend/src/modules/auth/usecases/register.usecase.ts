import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, EmailAlreadyExistsError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RegisterDTO } from '../dtos/auth.dto';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

@Injectable()
export class RegisterUseCase {
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: RegisterDTO): Promise<Either<AppError, AuthResponse>> {
    const existingUser = await this.userRepository.findByEmail(input.email);
    if (existingUser) {
      return left(new EmailAlreadyExistsError());
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    const user = await this.userRepository.create({
      displayName: input.displayName,
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

    return right(toAuthResponse(user));
  }
}
