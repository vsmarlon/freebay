import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '../domain/repositories/user.repository';
import { PasswordRecoveryRepository } from '../domain/repositories/password-recovery.repository';
import { RequestPasswordRecoveryDTO } from '../dtos/password-recovery.dto';
import { ResendService } from '../services/resend.service';

@Injectable()
export class RequestPasswordRecoveryUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly recoveryRepository: PasswordRecoveryRepository,
    private readonly resendService: ResendService,
  ) {}

  async execute(input: RequestPasswordRecoveryDTO): Promise<Either<AppError, { sent: boolean }>> {
    const userResult = await this.userRepository.findByEmail(input.email);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;

    if (!user) {
      return right({ sent: true });
    }

    const deleteResult = await this.recoveryRepository.deleteManyForUser(user.id);
    if (deleteResult.isLeft()) return left(deleteResult.value);

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = await bcrypt.hash(code, 10);

    const createResult = await this.recoveryRepository.create({
      user: { connect: { id: user.id } },
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      maxAttempts: 5,
    });
    if (createResult.isLeft()) return left(createResult.value);

    const resendMessageId = await this.resendService.sendRecoveryCode(user.email, code);

    const sentResult = await this.recoveryRepository.markSent(createResult.value.id, resendMessageId);
    if (sentResult.isLeft()) return left(sentResult.value);

    return right({ sent: true });
  }
}
