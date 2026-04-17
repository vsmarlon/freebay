import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Report, ReportReason } from '@prisma/client';
import {
  CreateReportInput,
  ReportWithRelations,
} from '../dtos/report.dto';

@Injectable()
export class CreateReportUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: CreateReportInput): Promise<Either<AppError, Report>> {
    if (input.targetType === 'USER') {
      const userExists = await this.prisma.user.findUnique({ where: { id: input.targetId } });
      if (!userExists) {
        return left(new NotFoundError('User'));
      }

      const existingReport = await this.prisma.report.findUnique({
        where: { reporterId_reportedUserId: { reporterId: input.reporterId, reportedUserId: input.targetId } },
      });

      if (existingReport) {
        return left(new BadRequestError('You have already reported this user'));
      }

      const report = await this.prisma.report.create({
        data: {
          reporterId: input.reporterId,
          reportedUserId: input.targetId,
          reason: input.reason as ReportReason,
          description: input.description,
        },
      });

      return right(report);
    }

    if (input.targetType === 'POST') {
      const postExists = await this.prisma.post.findUnique({ where: { id: input.targetId } });
      if (!postExists) {
        return left(new NotFoundError('Post'));
      }

      const existingReport = await this.prisma.report.findUnique({
        where: { reporterId_reportedPostId: { reporterId: input.reporterId, reportedPostId: input.targetId } },
      });

      if (existingReport) {
        return left(new BadRequestError('You have already reported this post'));
      }

      const report = await this.prisma.report.create({
        data: {
          reporterId: input.reporterId,
          reportedPostId: input.targetId,
          reason: input.reason as ReportReason,
          description: input.description,
        },
      });

      return right(report);
    }

    return left(new BadRequestError('Invalid target type'));
  }
}

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
