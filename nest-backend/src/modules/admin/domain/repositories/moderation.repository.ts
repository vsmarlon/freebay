import { Prisma, ReportStatus } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import {
  AdminReportRow,
  CreateModerationActionInput,
  ModerationActionRow,
} from '../../types/admin.types';

export abstract class ModerationRepository {
  abstract findReports(params: {
    status?: ReportStatus;
    cursorId: string | null;
    limit: number;
  }): RepositoryResponse<CursorPage<AdminReportRow>>;

  abstract findReportById(reportId: string): RepositoryResponse<AdminReportRow | null>;

  abstract resolveReport(
    reportId: string,
    data: { status: ReportStatus; reviewedById: string },
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }>;

  abstract recordAction(
    data: CreateModerationActionInput,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void>;

  abstract findActions(params: {
    cursorId: string | null;
    limit: number;
  }): RepositoryResponse<CursorPage<ModerationActionRow>>;

  abstract setUserSuspension(
    userId: string,
    data: { suspendedAt: Date | null; suspensionReason: string | null },
  ): RepositoryResponse<{ count: number }>;

  abstract userExists(userId: string): RepositoryResponse<boolean>;

  abstract softDeleteProduct(productId: string): RepositoryResponse<{ count: number }>;
  abstract softDeletePost(postId: string): RepositoryResponse<{ count: number }>;
  abstract softDeleteComment(commentId: string): RepositoryResponse<{ count: number }>;
}
