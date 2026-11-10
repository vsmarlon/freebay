import { Injectable } from '@nestjs/common';
import { BugReport } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CreateBugReportInput } from '../../dtos/bug-report.dto';

@Injectable()
export class BugReportDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async create(input: CreateBugReportInput): RepositoryResponse<BugReport> {
    return repositoryResponse(() => this.prisma.bugReport.create({
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
