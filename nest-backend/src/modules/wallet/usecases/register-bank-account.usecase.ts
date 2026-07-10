import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class RegisterBankAccountUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: {
    userId: string;
    bankCode: string;
    accountNumber: string;
    accountCheckDigit: string;
    branchNumber: string;
    branchCheckDigit: string;
    holderName: string;
    holderDocument: string;
  }): Promise<Either<AppError, { registered: boolean }>> {
    const user = await this.prisma.user.findUnique({ where: { id: input.userId } });
    if (!user) {
      return left(new NotFoundError('User'));
    }

    const wallet = await this.prisma.wallet.findUnique({ where: { userId: input.userId } });
    if (!wallet) {
      return left(new NotFoundError('Wallet'));
    }

    const recipientId = `rec_${uuidv4().replace(/-/g, '').substring(0, 16)}`;

    await this.prisma.wallet.update({
      where: { userId: input.userId },
      data: { recipientId },
    });

    return right({ registered: true });
  }
}
