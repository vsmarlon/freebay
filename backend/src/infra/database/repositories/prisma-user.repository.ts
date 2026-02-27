import { prisma } from '../prisma/client';
import { IUserRepository } from '@/domain/repositories';
import { UserEntity } from '@/domain/entities';

export class PrismaUserRepository implements IUserRepository {
  async findById(id: string): Promise<UserEntity | null> {
    return prisma.user.findUnique({ where: { id } });
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    return prisma.user.findUnique({ where: { email } });
  }

  async create(data: Omit<UserEntity, 'id' | 'createdAt' | 'updatedAt'>): Promise<UserEntity> {
    const prismaData = {
      ...data,
      role: data.role === 'GUEST' ? 'USER' : data.role,
    };
    return prisma.user.create({ data: prismaData });
  }

  async update(id: string, data: Partial<UserEntity>): Promise<UserEntity> {
    const { role, ...rest } = data;
    const prismaData = {
      ...rest,
      ...(role && { role: role === 'GUEST' ? 'USER' : role }),
    };
    return prisma.user.update({ where: { id }, data: prismaData });
  }
}
