import { ILikeRepository } from '@/domain/repositories';
import { LikeEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';

export class PrismaLikeRepository implements ILikeRepository {
  async findByUserAndPost(userId: string, postId: string): Promise<LikeEntity | null> {
    return prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
    });
  }

  async create(userId: string, postId: string): Promise<LikeEntity> {
    return prisma.like.create({
      data: { userId, postId },
    });
  }

  async delete(userId: string, postId: string): Promise<void> {
    await prisma.like.delete({
      where: { userId_postId: { userId, postId } },
    });
  }
}
