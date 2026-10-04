import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { Prisma } from '@prisma/client';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { UserResponse, toUserResponse } from '../dtos/user-response.class';
import { UpdateProfileInput } from '../dtos/user.dto';
import { RequestProfileVerificationUseCase } from './request-profile-verification.usecase';

@Injectable()
export class UpdateProfileUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly profileVerification: RequestProfileVerificationUseCase,
  ) {}

  async execute(input: UpdateProfileInput): Promise<Either<AppError, UserResponse>> {
    const { userId, cpf, profileVerificationCode, ...profile } = input;

    if (input.username) {
      const existingResult = await this.userRepository.findByUsername(input.username);
      if (existingResult.isLeft()) return left(existingResult.value);
      if (existingResult.value && existingResult.value.id !== userId) {
        return left(new UsernameAlreadyExistsError());
      }
    }

    if (cpf !== undefined) {
      const verified = await this.profileVerification.consume({
        userId,
        cpf,
        code: profileVerificationCode ?? '',
      });
      if (verified.isLeft()) return left(verified.value);
    }

    const updateData: Prisma.UserUpdateInput = {
      ...profile,
      ...(cpf !== undefined ? { cpf: cpf.replace(/\D/g, '') } : {}),
      ...(input.avatarUrl !== undefined ? { avatarBlurHash: null } : {}),
    };

    const userResult = await this.userRepository.update(userId, updateData);
    if (userResult.isLeft()) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }
    return right(toUserResponse(userResult.value, undefined, true));
  }
}
