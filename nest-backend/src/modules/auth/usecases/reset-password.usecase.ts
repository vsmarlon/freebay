import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidResetTokenError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ResetPasswordDTO } from '../dtos/auth.dto';

@Injectable()
export class ResetPasswordUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private redisService: RedisService,
  ) {}

  async execute(input: ResetPasswordDTO): Promise<Either<AppError, void>> {
    const redisKey = `password_reset:${input.token}`;
    const userId = await this.redisService.get(redisKey);

    if (!userId) {
      return left(new InvalidResetTokenError());
    }

    const passwordHash = await bcrypt.hash(input.password, 12);
    await this.userRepository.update(userId, { passwordHash });
    await this.redisService.del(redisKey);

    return right(undefined);
  }
}