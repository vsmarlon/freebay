import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class MarkAsReadUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(notificationId: string, userId: string): Promise<Either<AppError, { marked: boolean }>> {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification) {
      return left(new NotFoundError('Notification'));
    }

    if (notification.userId !== userId) {
      return left(new AppError('FORBIDDEN', 'Not authorized', 403));
    }

    await this.prisma.notification.update({
      where: { id: notificationId },
      data: { read: true },
    });

    return right({ marked: true });
  }
}
