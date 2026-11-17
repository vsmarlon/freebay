import { Injectable } from '@nestjs/common';
import { ModerationActionType, ReportStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ConflictError, DatabaseError, NotFoundError } from '@/shared/core/errors';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { ResolvableReportStatus } from '../dtos/admin.dto';

const ACTION_BY_STATUS: Record<ResolvableReportStatus, ModerationActionType> = {
  [ReportStatus.RESOLVED]: ModerationActionType.REPORT_RESOLVED,
  [ReportStatus.REJECTED]: ModerationActionType.REPORT_REJECTED,
};

@Injectable()
export class ResolveReportUseCase {
  constructor(private readonly moderationRepository: ModerationDatabaseRepository) {}

  async execute(input: {
    reportId: string;
    adminId: string;
    status: ResolvableReportStatus;
    note?: string;
  }): Promise<Either<AppError, void>> {
    const reportResult = await this.moderationRepository.findReportById(input.reportId);
    if (reportResult.isLeft()) return left(reportResult.value);
    if (!reportResult.value) return left(new NotFoundError('Denúncia'));

    // REVIEWED is a legacy state left by the old flow; it must still be resolvable.
    if (reportResult.value.status !== ReportStatus.PENDING
      && reportResult.value.status !== ReportStatus.REVIEWED) {
      return left(new ConflictError('Esta denúncia já foi revisada'));
    }

    try {
      const resolved = await this.moderationRepository.resolveReportAndRecord({
        reportId: input.reportId,
        status: input.status,
        adminId: input.adminId,
        action: ACTION_BY_STATUS[input.status],
        note: input.note ?? null,
      });
      if (!resolved) {
        return left(new ConflictError('Esta denúncia já foi revisada'));
      }
    } catch {
      return left(new DatabaseError('Failed to resolve report'));
    }

    return right(undefined);
  }
}
