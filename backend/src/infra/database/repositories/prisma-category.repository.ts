import { prisma } from '../prisma/client';
import { CategoryEntity } from '@/domain/entities';
import { ICategoryRepository } from '@/domain/repositories';

export class PrismaCategoryRepository implements ICategoryRepository {
  async getCategoryTree(): Promise<CategoryEntity[]> {
    const categories = await prisma.category.findMany({
      where: { parentId: null },
      include: {
        children: {
          include: {
            children: {
              include: {
                children: true,
              },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    return categories as unknown as CategoryEntity[];
  }

  async getAllCategories(): Promise<CategoryEntity[]> {
    const categories = await prisma.category.findMany({
      orderBy: { name: 'asc' },
      include: {
        children: true,
      },
    });

    return categories as unknown as CategoryEntity[];
  }

  async getCategoryById(id: string): Promise<CategoryEntity | null> {
    const category = await prisma.category.findUnique({
      where: { id },
      include: {
        children: true,
        parent: true,
      },
    });

    return category as unknown as CategoryEntity | null;
  }

  async createCategory(data: {
    name: string;
    slug: string;
    parentId?: string;
  }): Promise<CategoryEntity> {
    const category = await prisma.category.create({
      data: {
        name: data.name,
        slug: data.slug,
        parentId: data.parentId || null,
      },
    });

    return category as unknown as CategoryEntity;
  }
}
