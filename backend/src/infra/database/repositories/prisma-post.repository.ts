import { IPostRepository } from '@/domain/repositories';
import { PostEntity } from '@/domain/entities';
import { prisma } from '../prisma/client';

export class PrismaPostRepository implements IPostRepository {
  async findById(id: string): Promise<PostEntity | null> {
    const post = await prisma.post.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isVerified: true,
            reputationScore: true,
            totalReviews: true,
          },
        },
        product: {
          include: {
            images: {
              orderBy: { order: 'asc' },
              take: 1,
            },
          },
        },
      },
    });

    if (!post) return null;

    const productImage = post.product?.images?.[0]?.url ?? null;

    return {
      ...post,
      imageUrl: post.imageUrl ?? productImage,
      product: post.product
        ? {
            id: post.product.id,
            title: post.product.title,
            description: post.product.description,
            price: post.product.price,
            condition: post.product.condition,
          }
        : null,
    } as PostEntity;
  }

  async findByUserId(
    userId: string,
    params: { cursor?: string; limit?: number },
  ): Promise<PostEntity[]> {
    const limit = params.limit ?? 20;
    return prisma.post.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
    });
  }

  async findFeed(params: {
    userId: string;
    cursor?: string;
    limit?: number;
  }): Promise<PostEntity[]> {
    const limit = params.limit ?? 20;
    const posts = await prisma.post.findMany({
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
            reputationScore: true,
            totalReviews: true,
          },
        },
        product: {
          include: {
            images: {
              orderBy: { order: 'asc' },
              take: 1,
            },
          },
        },
      },
    });

    return posts.map((post) => {
      const productImage = post.product?.images?.[0]?.url ?? null;
      return {
        ...post,
        user: post.user,
        imageUrl: post.imageUrl ?? productImage,
        product: post.product
          ? {
              id: post.product.id,
              title: post.product.title,
              description: post.product.description,
              price: post.product.price,
              condition: post.product.condition,
            }
          : null,
      };
    }) as PostEntity[];
  }

  async create(data: {
    content: string | null;
    imageUrl: string | null;
    type: 'PRODUCT' | 'REGULAR';
    userId: string;
  }): Promise<PostEntity> {
    return prisma.post.create({ data });
  }

  async delete(id: string): Promise<void> {
    await prisma.post.delete({ where: { id } });
  }

  async incrementLikes(id: string): Promise<void> {
    await prisma.post.update({ where: { id }, data: { likesCount: { increment: 1 } } });
  }

  async decrementLikes(id: string): Promise<void> {
    await prisma.post.update({ where: { id }, data: { likesCount: { decrement: 1 } } });
  }

  async incrementComments(id: string): Promise<void> {
    await prisma.post.update({ where: { id }, data: { commentsCount: { increment: 1 } } });
  }

  async incrementShares(id: string): Promise<void> {
    await prisma.post.update({ where: { id }, data: { sharesCount: { increment: 1 } } });
  }
}
