import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Report } from '@prisma/client';
import { ReportWithRelations } from '../dtos/report.dto';

@Injectable()
export class GetReportsUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(status?: string): Promise<Either<AppError, ReportWithRelations[]>> {
    const where = status ? { status: status as Report['status'] } : {};

    const reports = await this.prisma.report.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    const result: ReportWithRelations[] = reports.map(r => ({
      id: r.id,
      reason: r.reason,
      description: r.description,
      status: r.status,
      createdAt: r.createdAt,
      reporterId: r.reporterId,
      reportedUserId: r.reportedUserId,
      reportedPostId: r.reportedPostId,
    }));

    return right(result);
  }
}
