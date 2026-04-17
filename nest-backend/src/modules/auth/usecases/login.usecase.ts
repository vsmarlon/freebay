import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidCredentialsError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { LoginDTO } from '../dtos/auth.dto';
import { LoginResponse, toLoginResponse } from '../mappers/auth.mapper';

@Injectable()
export class LoginUseCase {
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: LoginDTO): Promise<Either<AppError, LoginResponse>> {
    const user = await this.userRepository.findByEmail(input.email);
    if (!user) {
      return left(new InvalidCredentialsError());
    }

    const passwordMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!passwordMatch) {
      return left(new InvalidCredentialsError());
    }

    return right(toLoginResponse(user));
  }
}
