import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { PhoneVerificationRepository } from '../domain/repositories/phone-verification.repository';
import { SmsService } from '../services/sms.service';

export interface RegisterPhoneInput {
  userId: string;
  phone: string;
}

@Injectable()
export class RegisterPhoneUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly phoneVerificationRepository: PhoneVerificationRepository,
    private readonly smsService: SmsService,
  ) {}

  async execute(input: RegisterPhoneInput): Promise<Either<AppError, void>> {
    const phoneDigits = input.phone.replace(/\D/g, '');

    if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      return left(new AppError('INVALID_PHONE', 'Telefone inválido. Informe o DDD e o número.'));
    }

    const deleteResult = await this.phoneVerificationRepository.deleteManyForUser(input.userId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = await bcrypt.hash(code, 10);

    const createResult = await this.phoneVerificationRepository.create({
      user: { connect: { id: input.userId } },
      phone: phoneDigits,
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      maxAttempts: 5,
    });
    if (isLeft(createResult)) return left(createResult.value);

    const updateResult = await this.userRepository.update(input.userId, {
      phone: phoneDigits,
      phoneVerified: false,
    });
    if (isLeft(updateResult)) return left(updateResult.value);

    const providerMessageId = await this.smsService.sendVerificationCode(phoneDigits, code);

    const sentResult = await this.phoneVerificationRepository.markSent(
      createResult.value.id,
      'twilio',
      providerMessageId,
    );
    if (isLeft(sentResult)) return left(sentResult.value);

    return right(undefined);
  }
}
