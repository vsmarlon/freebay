import { Injectable } from '@nestjs/common';
import { Category } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { CategoryWithChildren } from '../../types/category.types';

@Injectable()
export class CategoryDatabaseRepository extends BasePrismaRepository implements CategoryRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(): RepositoryResponse<CategoryWithChildren[]> {
    return this.safeRun(async () => {
      const categories = await this.prisma.category.findMany({ orderBy: { name: 'asc' } });
      return this.buildTree(categories);
    }, 'Erro ao listar categorias');
  }

  async findById(id: string): RepositoryResponse<Category | null> {
    return this.safeRun(() => this.prisma.category.findUnique({ where: { id } }), 'Erro ao buscar categoria');
  }

  private buildTree(categories: Category[]): CategoryWithChildren[] {
    const byId = new Map<string, CategoryWithChildren>(
      categories.map((c) => [c.id, { ...c, children: [] }]),
    );
    const roots: CategoryWithChildren[] = [];
    for (const c of categories) {
      const node = byId.get(c.id)!;
      const parent = c.parentId ? byId.get(c.parentId) : undefined;
      if (parent) parent.children.push(node);
      else roots.push(node);
    }
    return roots;
  }
}
