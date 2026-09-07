import { Injectable } from '@nestjs/common';
import { ReportStatus } from '@prisma/client';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CursorPage, clampLimit, decodeIdCursor } from '@/shared/core/pagination';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { AdminReportRow } from '../types/admin.types';

@Injectable()
export class ListReportsUseCase {
  constructor(private readonly moderationRepository: ModerationDatabaseRepository) {}

  async execute(input: {
    status?: ReportStatus;
    cursor?: string;
    limit?: number;
  }): Promise<Either<AppError, CursorPage<AdminReportRow>>> {
    const result = await this.moderationRepository.findReports({
      status: input.status,
      cursorId: decodeIdCursor(input.cursor),
      limit: clampLimit(input.limit),
    });
    if (isLeft(result)) return left(result.value);

    return right(result.value);
  }
}
