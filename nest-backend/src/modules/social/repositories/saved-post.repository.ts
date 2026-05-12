import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class PrismaSavedPostRepository {
  constructor(private prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string) {
    return this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
    });
  }

  async save(userId: string, postId: string) {
    return this.prisma.savedPost.create({
      data: {
        user: { connect: { id: userId } },
        post: { connect: { id: postId } },
      },
    });
  }

  async unsave(userId: string, postId: string) {
    return this.prisma.savedPost.delete({
      where: { userId_postId: { userId, postId } },
    });
  }
}
