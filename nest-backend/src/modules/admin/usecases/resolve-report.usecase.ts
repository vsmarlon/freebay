import { Injectable } from '@nestjs/common';
import { ModerationActionType } from '@prisma/client';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, ConflictError, NotFoundError } from '@/shared/core/errors';
import { ModerationRepository } from '../domain/repositories/moderation.repository';
import { ResolvableReportStatus } from '../dtos/admin.dto';

const ACTION_BY_STATUS: Record<ResolvableReportStatus, ModerationActionType> = {
  REVIEWED: 'REPORT_REVIEWED',
  RESOLVED: 'REPORT_RESOLVED',
  REJECTED: 'REPORT_REJECTED',
};

@Injectable()
export class ResolveReportUseCase {
  constructor(private readonly moderationRepository: ModerationRepository) {}

  async execute(input: {
    reportId: string;
    adminId: string;
    status: ResolvableReportStatus;
    note?: string;
  }): Promise<Either<AppError, void>> {
    const reportResult = await this.moderationRepository.findReportById(input.reportId);
    if (isLeft(reportResult)) return left(reportResult.value);
    if (!reportResult.value) return left(new NotFoundError('Denúncia'));

    if (reportResult.value.status !== 'PENDING') {
      return left(new ConflictError('Esta denúncia já foi revisada'));
    }

    const resolveResult = await this.moderationRepository.resolveReport(input.reportId, {
      status: input.status,
      reviewedById: input.adminId,
    });
    if (isLeft(resolveResult)) return left(resolveResult.value);
    if (resolveResult.value.count === 0) {
      return left(new ConflictError('Esta denúncia já foi revisada'));
    }

    const actionResult = await this.moderationRepository.recordAction({
      actorId: input.adminId,
      targetType: 'REPORT',
      targetId: input.reportId,
      action: ACTION_BY_STATUS[input.status],
      reason: input.note ?? null,
      reportId: input.reportId,
    });
    if (isLeft(actionResult)) return left(actionResult.value);

    return right(undefined);
  }
}
