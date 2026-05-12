import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaShareRepository {
  constructor(private prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string) {
    return this.prisma.share.findUnique({
      where: { userId_postId: { userId, postId } },
    });
  }

  async create(data: Prisma.ShareCreateInput) {
    return this.prisma.share.create({ data });
  }

  async delete(userId: string, postId: string) {
    return this.prisma.share.delete({
      where: { userId_postId: { userId, postId } },
    });
  }

  async findPostsRepostedByUser(
    userId: string,
    params: { limit: number; cursor?: string },
  ) {
    return this.prisma.share.findMany({
      where: { userId },
      include: {
        post: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
            product: { include: { images: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: params.limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
    });
  }

  async exists(userId: string, postId: string) {
    const share = await this.prisma.share.findUnique({
      where: { userId_postId: { userId, postId } },
    });
    return !!share;
  }
}
