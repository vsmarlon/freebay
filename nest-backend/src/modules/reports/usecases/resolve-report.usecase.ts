import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class ResolveReportUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: { reportId: string; status: 'REVIEWED' | 'RESOLVED' | 'REJECTED'; adminNote?: string }): Promise<Either<AppError, { resolved: boolean }>> {
    const report = await this.prisma.report.findUnique({
      where: { id: input.reportId },
    });

    if (!report) {
      return left(new NotFoundError('Report'));
    }

    await this.prisma.report.update({
      where: { id: input.reportId },
      data: { status: input.status, reviewedAt: new Date() },
    });

    if (input.status === 'RESOLVED' && report.reportedUserId) {
      await this.prisma.user.update({
        where: { id: report.reportedUserId },
        data: { isVerified: false },
      });
    }

    return right({ resolved: true });
  }
}
