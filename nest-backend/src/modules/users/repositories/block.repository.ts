import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class BlockRepository {
  constructor(private prisma: PrismaService) {}

  async block(blockerId: string, blockedId: string) {
    return this.prisma.block.create({
      data: { blockerId, blockedId },
    });
  }

  async unblock(blockerId: string, blockedId: string) {
    return this.prisma.block.delete({
      where: {
        blockerId_blockedId: { blockerId, blockedId },
      },
    });
  }

  async isBlocked(blockerId: string, blockedId: string): Promise<boolean> {
    const block = await this.prisma.block.findUnique({
      where: { blockerId_blockedId: { blockerId, blockedId } },
    });
    return !!block;
  }

  async getBlockedUsers(userId: string, limit: number, offset: number) {
    return this.prisma.user.findMany({
      where: { blocksGiven: { some: { blockerId: userId } } },
      take: limit,
      skip: offset,
      select: {
        id: true,
        displayName: true,
        avatarUrl: true,
        isVerified: true,
        reputationScore: true,
      },
    });
  }
}
