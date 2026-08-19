import { Injectable } from '@nestjs/common';
import { BugReport } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { BugReportRepository } from '../../domain/repositories/bug-report.repository';
import { CreateBugReportInput } from '../../dtos/bug-report.dto';

@Injectable()
export class BugReportDatabaseRepository extends BasePrismaRepository implements BugReportRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(input: CreateBugReportInput): RepositoryResponse<BugReport> {
    return this.safeRun(() => this.prisma.bugReport.create({
      data: {
        userId: input.userId,
        description: input.description,
        appVersion: input.appVersion,
        platform: input.platform,
        screenContext: input.screenContext,
      },
    }), 'Erro ao registrar relatório de bug');
  }
}
