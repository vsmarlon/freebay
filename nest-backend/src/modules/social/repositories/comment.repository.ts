import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';

@Injectable()
export class PrismaCommentRepository {
  constructor(private prisma: PrismaService) {}

  async findByPostId(postId: string, params: { limit: number; cursor?: string }) {
    return this.prisma.comment.findMany({
      where: { postId, parentId: null },
      orderBy: { createdAt: 'asc' },
      take: params.limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
      include: {
        user: { select: USER_SELECT_BASIC },
        replies: {
          include: {
            user: { select: USER_SELECT_BASIC },
            _count: true,
          },
          orderBy: { createdAt: 'asc' as const },
        },
        _count: true,
      },
    });
  }

  async create(data: Prisma.CommentCreateInput) {
    return this.prisma.comment.create({ data });
  }
}
