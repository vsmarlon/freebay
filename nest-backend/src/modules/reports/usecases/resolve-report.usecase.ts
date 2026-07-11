import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ReportRepository } from '../domain/repositories/report.repository';

@Injectable()
export class ResolveReportUseCase {
  constructor(private readonly reportRepository: ReportRepository) {}

  async execute(input: { reportId: string; status: 'REVIEWED' | 'RESOLVED' | 'REJECTED'; adminNote?: string }): Promise<Either<AppError, void>> {
    const reportResult = await this.reportRepository.findReportById(input.reportId);
    if (isLeft(reportResult)) return left(reportResult.value);
    if (!reportResult.value) return left(new NotFoundError('Report'));

    const updateResult = await this.reportRepository.updateReport(input.reportId, {
      status: input.status,
      reviewedAt: new Date(),
    });
    if (isLeft(updateResult)) return left(updateResult.value);

    if (input.status === 'RESOLVED' && reportResult.value.reportedUserId) {
      const userUpdateResult = await this.reportRepository.updateUser(reportResult.value.reportedUserId, {
        isVerified: false,
      });
      if (isLeft(userUpdateResult)) return left(userUpdateResult.value);
    }

    return right(undefined);
  }
}
