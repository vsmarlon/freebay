import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class RegisterFcmTokenUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(userId: string, fcmToken: string): Promise<Either<AppError, { registered: boolean }>> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return right({ registered: true });
  }
}
