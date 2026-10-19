import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from './prisma.service';

@Injectable()
export class AuthSessionStateDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findInvalidBefore(userId: string): Promise<Date | null> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { sessionsInvalidBefore: true },
    });
    return user?.sessionsInvalidBefore ?? null;
  }

  async advanceInvalidBefore(
    userId: string,
    cutoff: Date,
  ): Promise<void> {
    await this.advanceInvalidBeforeInTransaction(this.prisma, userId, cutoff);
  }

  async advanceInvalidBeforeInTransaction(
    client: Prisma.TransactionClient | PrismaService,
    userId: string,
    cutoff: Date,
  ): Promise<void> {
    await client.user.updateMany({
      where: {
        id: userId,
        OR: [{ sessionsInvalidBefore: null }, { sessionsInvalidBefore: { lt: cutoff } }],
      },
      data: { sessionsInvalidBefore: cutoff },
    });
  }
}
