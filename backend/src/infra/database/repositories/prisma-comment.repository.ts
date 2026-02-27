import { ICommentRepository } from '@/domain/repositories';
import { CommentEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';

export class PrismaCommentRepository implements ICommentRepository {
  async findByPostId(
    postId: string,
    params: { cursor?: string; limit?: number },
  ): Promise<CommentEntity[]> {
    const limit = params.limit ?? 20;
    const comments = await prisma.comment.findMany({
      where: { postId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isVerified: true,
          },
        },
      },
    });

    return comments.map((comment) => ({
      id: comment.id,
      content: comment.content,
      userId: comment.userId,
      postId: comment.postId,
      createdAt: comment.createdAt,
      user: comment.user,
    }));
  }

  async create(data: { content: string; userId: string; postId: string }): Promise<CommentEntity> {
    return prisma.comment.create({ data });
  }
}
