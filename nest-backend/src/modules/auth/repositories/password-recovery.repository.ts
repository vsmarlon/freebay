import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PasswordRecoveryCode, Prisma } from '@prisma/client';

@Injectable()
export class PrismaPasswordRecoveryRepository {
  constructor(private prisma: PrismaService) {}

  async create(data: Prisma.PasswordRecoveryCodeCreateInput): Promise<PasswordRecoveryCode> {
    return this.prisma.passwordRecoveryCode.create({ data });
  }

  async findLatestActiveByEmail(email: string): Promise<PasswordRecoveryCode | null> {
    return this.prisma.passwordRecoveryCode.findFirst({
      where: {
        user: { email },
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { requestedAt: 'desc' },
    });
  }

  async findLatestByEmail(email: string): Promise<PasswordRecoveryCode | null> {
    return this.prisma.passwordRecoveryCode.findFirst({
      where: { user: { email } },
      orderBy: { requestedAt: 'desc' },
    });
  }

  async incrementAttempts(id: string): Promise<PasswordRecoveryCode> {
    return this.prisma.passwordRecoveryCode.update({
      where: { id },
      data: { attempts: { increment: 1 } },
    });
  }

  async markSent(id: string, resendMessageId?: string | null): Promise<PasswordRecoveryCode> {
    return this.prisma.passwordRecoveryCode.update({
      where: { id },
      data: {
        sentAt: new Date(),
        resendMessageId: resendMessageId ?? undefined,
      },
    });
  }

  async markUsed(id: string): Promise<PasswordRecoveryCode> {
    return this.prisma.passwordRecoveryCode.update({
      where: { id },
      data: { usedAt: new Date() },
    });
  }

  async deleteManyForUser(userId: string): Promise<void> {
    await this.prisma.passwordRecoveryCode.deleteMany({ where: { userId } });
  }
}
