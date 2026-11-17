import { Injectable } from '@nestjs/common';
import { Prisma, ProductPauseReason, ProductStatus, ReportStatus } from '@prisma/client';
import { Transactional, TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, buildIdCursorPage } from '@/shared/core/pagination';
import {
  AdminReportRow,
  CreateModerationActionInput,
  ModerationActionRow,
} from '../../types/admin.types';

const USER_BRIEF_SELECT = {
  id: true,
  displayName: true,
  username: true,
  avatarUrl: true,
  suspendedAt: true,
} satisfies Prisma.UserSelect;

const REPORT_SELECT = {
  id: true,
  targetType: true,
  reason: true,
  description: true,
  status: true,
  createdAt: true,
  reviewedAt: true,
  reviewedById: true,
  reportedPostId: true,
  reportedDirectConversationId: true,
  reportedOrderChatId: true,
  reportedDirectMessageId: true,
  reportedChatMessageId: true,
  reporter: { select: USER_BRIEF_SELECT },
  reportedUser: { select: USER_BRIEF_SELECT },
} satisfies Prisma.ReportSelect;

@Injectable()
export class ModerationDatabaseRepository
{
  constructor(
    private readonly prisma: PrismaService,
    private readonly txHost: TransactionHost<TransactionalAdapterPrisma>,
  ) {
  }

  async findReports(params: {
    status?: ReportStatus;
    cursorId: string | null;
    limit: number;
  }): RepositoryResponse<CursorPage<AdminReportRow>> {
    return repositoryResponse(async () => {
      const rows = await this.prisma.report.findMany({
        where: params.status ? { status: params.status } : {},
        orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
        take: params.limit + 1,
        ...(params.cursorId ? { cursor: { id: params.cursorId }, skip: 1 } : {}),
        select: REPORT_SELECT,
      });

      return buildIdCursorPage(rows, params.limit);
    }, 'Erro ao buscar denúncias');
  }

  async findReportById(reportId: string): RepositoryResponse<AdminReportRow | null> {
    return repositoryResponse(async () => {
      const report = await this.prisma.report.findUnique({
        where: { id: reportId },
        select: REPORT_SELECT,
      });
      return report;
    }, 'Erro ao buscar denúncia');
  }

  async resolveReport(
    reportId: string,
    data: { status: ReportStatus; reviewedById: string },
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await (tx ?? this.prisma).report.updateMany({
        where: {
          id: reportId,
          // REVIEWED is a legacy intermediate state; it must still be resolvable.
          status: { in: [ReportStatus.PENDING, ReportStatus.REVIEWED] },
        },
        data: {
          status: data.status,
          reviewedAt: new Date(),
          reviewedById: data.reviewedById,
        },
      });
      return { count: result.count };
    }, 'Erro ao resolver denúncia');
  }

  /**
   * Resolve the report and record its audit action in one transaction. A
   * failure after the status change used to leave a resolved report with no
   * moderation trail.
   */
  @Transactional()
  async resolveReportAndRecord(input: {
    reportId: string;
    status: ReportStatus;
    adminId: string;
    action: CreateModerationActionInput['action'];
    note: string | null;
  }): Promise<boolean> {
    const resolved = await this.resolveReport(
      input.reportId,
      { status: input.status, reviewedById: input.adminId },
      this.txHost.tx,
    );
    if (resolved.isLeft()) throw new Error(resolved.value.message);
    if (resolved.value.count === 0) return false;

    const recorded = await this.recordAction({
      actorId: input.adminId,
      targetType: 'REPORT',
      targetId: input.reportId,
      action: input.action,
      reason: input.note,
      reportId: input.reportId,
    }, this.txHost.tx);
    if (recorded.isLeft()) throw new Error(recorded.value.message);
    return true;
  }

  async recordAction(
    data: CreateModerationActionInput,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await (tx ?? this.prisma).moderationAction.create({
        data: {
          actorId: data.actorId,
          targetType: data.targetType,
          targetId: data.targetId,
          action: data.action,
          reason: data.reason ?? null,
          reportId: data.reportId ?? null,
        },
      });
    }, 'Erro ao registrar ação de moderação');
  }

  async findActions(params: {
    cursorId: string | null;
    limit: number;
  }): RepositoryResponse<CursorPage<ModerationActionRow>> {
    return repositoryResponse(async () => {
      const rows = await this.prisma.moderationAction.findMany({
        orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
        take: params.limit + 1,
        ...(params.cursorId ? { cursor: { id: params.cursorId }, skip: 1 } : {}),
        select: {
          id: true,
          actorId: true,
          targetType: true,
          targetId: true,
          action: true,
          reason: true,
          reportId: true,
          createdAt: true,
          actor: { select: { displayName: true } },
        },
      });

      const mapped = rows.map((row) => ({
        id: row.id,
        actorId: row.actorId,
        actorDisplayName: row.actor.displayName,
        targetType: row.targetType,
        targetId: row.targetId,
        action: row.action,
        reason: row.reason,
        reportId: row.reportId,
        createdAt: row.createdAt,
      }));

      return buildIdCursorPage(mapped, params.limit);
    }, 'Erro ao buscar histórico de moderação');
  }

  async setUserSuspension(
    userId: string,
    data: { suspendedAt: Date | null; suspensionReason: string | null },
  ): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await this.prisma.user.updateMany({
        where: {
          id: userId,
          deletedAt: null,
          suspendedAt: data.suspendedAt ? null : { not: null },
        },
        data: { suspendedAt: data.suspendedAt, suspensionReason: data.suspensionReason },
      });
      return { count: result.count };
    }, 'Erro ao atualizar suspensão do usuário');
  }

  async userExists(userId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const count = await this.prisma.user.count({ where: { id: userId, deletedAt: null } });
      return count > 0;
    }, 'Erro ao buscar usuário');
  }

  async softDeleteProduct(productId: string): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await this.prisma.product.updateMany({
        where: { id: productId, deletedAt: null },
        data: { deletedAt: new Date(), status: ProductStatus.PAUSED, pauseReason: ProductPauseReason.MODERATION },
      });
      return { count: result.count };
    }, 'Erro ao remover produto');
  }

  async softDeletePost(postId: string): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await this.prisma.post.updateMany({
        where: { id: postId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      return { count: result.count };
    }, 'Erro ao remover publicação');
  }

  async softDeleteComment(commentId: string): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await this.prisma.comment.updateMany({
        where: { id: commentId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      return { count: result.count };
    }, 'Erro ao remover comentário');
  }
}
