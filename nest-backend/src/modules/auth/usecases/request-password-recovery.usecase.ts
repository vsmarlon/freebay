import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { PrismaPasswordRecoveryRepository } from '../repositories/password-recovery.repository';
import { RequestPasswordRecoveryDTO } from '../dtos/password-recovery.dto';
import { ResendService } from '../services/resend.service';

@Injectable()
export class RequestPasswordRecoveryUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private recoveryRepository: PrismaPasswordRecoveryRepository,
    private resendService: ResendService,
  ) {}

  async execute(input: RequestPasswordRecoveryDTO): Promise<Either<AppError, { sent: boolean }>> {
    const user = await this.userRepository.findByEmail(input.email);
    if (!user) {
      return right({ sent: true });
    }

    await this.recoveryRepository.deleteManyForUser(user.id);

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = await bcrypt.hash(code, 10);
    const recovery = await this.recoveryRepository.create({
      user: { connect: { id: user.id } },
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      maxAttempts: 5,
    });

    const resendMessageId = await this.resendService.sendRecoveryCode(user.email, code);
    await this.recoveryRepository.markSent(recovery.id, resendMessageId);

    return right({ sent: true });
  }
}
