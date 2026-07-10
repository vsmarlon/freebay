import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetNotificationsOutput } from '../dtos/notification.dto';

@Injectable()
export class GetNotificationsUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(userId: string, limit = 20): Promise<Either<AppError, GetNotificationsOutput>> {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return right(notifications);
  }
}
