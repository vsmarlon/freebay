import { Injectable } from '@nestjs/common';
import { Category } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CategoryWithChildren } from '../../types/category.types';

@Injectable()
export class CategoryDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findAll(): RepositoryResponse<CategoryWithChildren[]> {
    return repositoryResponse(async () => {
      const categories = await this.prisma.category.findMany({ orderBy: { name: 'asc' } });
      return this.buildTree(categories);
    }, 'Erro ao listar categorias');
  }

  async findById(id: string): RepositoryResponse<Category | null> {
    return repositoryResponse(() => this.prisma.category.findUnique({ where: { id } }), 'Erro ao buscar categoria');
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
