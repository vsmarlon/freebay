import { Injectable } from '@nestjs/common';
import { PrismaClient, Category } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CategoryRepository } from '../../domain/repositories/category.repository';
import { CategoryWithChildren } from '../../types/category.types';

@Injectable()
export class CategoryDatabaseRepository implements CategoryRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findAll(): RepositoryResponse<CategoryWithChildren[]> {
    try {
      return right(await this.prisma.category.findMany({
        where: { parentId: null },
        include: { children: true },
        orderBy: { name: 'asc' },
      }));
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
}
