import { Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { EmailService } from '@/shared/infra/email/email.service';
import { ForgotPasswordDTO } from '../dtos/auth.dto';

const RESET_TTL_SECONDS = 900;

@Injectable()
export class ForgotPasswordUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private redisService: RedisService,
    private emailService: EmailService,
  ) {}

  async execute(input: ForgotPasswordDTO): Promise<Either<AppError, void>> {
    const user = await this.userRepository.findByEmail(input.email);

    if (!user || user.isGuest) {
      return right(undefined);
    }

    const token = randomBytes(32).toString('hex');
    await this.redisService.add(`password_reset:${token}`, user.id, RESET_TTL_SECONDS);
    await this.emailService.sendPasswordReset(user.email, token);

    return right(undefined);
  }
}