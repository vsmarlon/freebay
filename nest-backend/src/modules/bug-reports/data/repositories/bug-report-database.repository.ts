import { Injectable } from '@nestjs/common';
import { PrismaClient, BugReport } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { BugReportRepository } from '../../domain/repositories/bug-report.repository';
import { CreateBugReportInput } from '../../dtos/bug-report.dto';

@Injectable()
export class BugReportDatabaseRepository implements BugReportRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(input: CreateBugReportInput): RepositoryResponse<BugReport> {
    try {
      return right(
        await this.prisma.bugReport.create({
          data: {
            userId: input.userId,
            description: input.description,
            appVersion: input.appVersion,
            platform: input.platform,
            screenContext: input.screenContext,
          },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao registrar relatório de bug'));
    }
  }
}
