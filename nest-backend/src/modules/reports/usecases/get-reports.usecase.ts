import { Injectable } from '@nestjs/common';
import { Either, right, left, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { Report } from '@prisma/client';
import { ReportWithRelations } from '../dtos/report.dto';
import { ReportRepository } from '../domain/repositories/report.repository';

@Injectable()
export class GetReportsUseCase {
  constructor(private readonly reportRepository: ReportRepository) {}

  async execute(status?: string): Promise<Either<AppError, ReportWithRelations[]>> {
    const where = status ? { status: status as Report['status'] } : {};

    const result = await this.reportRepository.findAllReports(where);
    if (isLeft(result)) return left(result.value);

    const mapped: ReportWithRelations[] = result.value.map(r => ({
      id: r.id,
      reason: r.reason,
      description: r.description,
      status: r.status,
      createdAt: r.createdAt,
      reporterId: r.reporterId,
      reportedUserId: r.reportedUserId,
      reportedPostId: r.reportedPostId,
    }));

    return right(mapped);
  }
}
