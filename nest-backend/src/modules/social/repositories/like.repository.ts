import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaLikeRepository {
  constructor(private prisma: PrismaService) {}

  async findByPostId(postId: string) {
    return this.prisma.like.findMany({ where: { postId } });
  }

  async findByCommentId(commentId: string) {
    return this.prisma.commentLike.findMany({ where: { commentId } });
  }

  async findPostLike(userId: string, postId: string) {
    return this.prisma.like.findFirst({ where: { userId, postId } });
  }

  async createLike(data: Prisma.LikeCreateInput) {
    return this.prisma.like.create({ data });
  }

  async createCommentLike(data: Prisma.CommentLikeCreateInput) {
    return this.prisma.commentLike.create({ data });
  }

  async deleteLike(data: Prisma.LikeWhereUniqueInput) {
    return this.prisma.like.delete({ where: data });
  }

  async deletePostLikeByUser(userId: string, postId: string) {
    return this.prisma.like.delete({
      where: { userId_postId: { userId, postId } },
    });
  }

  async deleteCommentLike(data: Prisma.CommentLikeWhereUniqueInput) {
    return this.prisma.commentLike.delete({ where: data });
  }

  async findLikedByUserId(userId: string) {
    return this.prisma.like.findMany({
      where: { userId },
      include: {
        post: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
            _count: { select: { likes: true, comments: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
