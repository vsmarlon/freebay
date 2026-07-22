import { Injectable } from '@nestjs/common';
import { Category } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { CategoryWithChildren } from '../../types/category.types';

@Injectable()
export class CategoryDatabaseRepository implements CategoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(): RepositoryResponse<CategoryWithChildren[]> {
    try {
      const categories = await this.prisma.category.findMany({
        orderBy: { name: 'asc' },
      });
      return right(this.buildTree(categories));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao listar categorias'));
    }
  }

  async findById(id: string): RepositoryResponse<Category | null> {
    try {
      return right(await this.prisma.category.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar categoria'));
    }
  }

  private buildTree(categories: Category[]): CategoryWithChildren[] {
    const byId = new Map<string, CategoryWithChildren>(
      categories.map((category) => [category.id, { ...category, children: [] }]),
    );

    const roots: CategoryWithChildren[] = [];
    for (const category of categories) {
      const node = byId.get(category.id)!;
      const parent = category.parentId ? byId.get(category.parentId) : undefined;
      if (parent) {
        parent.children.push(node);
      } else {
        roots.push(node);
      }
    }

    return roots;
  }
}
