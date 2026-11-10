import { Injectable } from '@nestjs/common';
import { ModerationActionType, ModerationTargetType, ReportStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ConflictError, NotFoundError } from '@/shared/core/errors';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { ResolvableReportStatus } from '../dtos/admin.dto';

const ACTION_BY_STATUS: Record<ResolvableReportStatus, ModerationActionType> = {
  [ReportStatus.REVIEWED]: ModerationActionType.REPORT_REVIEWED,
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

    if (reportResult.value.status !== ReportStatus.PENDING) {
      return left(new ConflictError('Esta denúncia já foi revisada'));
    }

    const resolveResult = await this.moderationRepository.resolveReport(input.reportId, {
      status: input.status,
      reviewedById: input.adminId,
    });
    if (resolveResult.isLeft()) return left(resolveResult.value);
    if (resolveResult.value.count === 0) {
      return left(new ConflictError('Esta denúncia já foi revisada'));
    }

    const actionResult = await this.moderationRepository.recordAction({
      actorId: input.adminId,
      targetType: ModerationTargetType.REPORT,
      targetId: input.reportId,
      action: ACTION_BY_STATUS[input.status],
      reason: input.note ?? null,
      reportId: input.reportId,
    });
    if (actionResult.isLeft()) return left(actionResult.value);

    return right(undefined);
  }
}
