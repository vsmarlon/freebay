import { RepositoryResponse } from '@/shared/core/either';
import { BugReport } from '@prisma/client';
import { CreateBugReportInput } from '../../dtos/bug-report.dto';

export abstract class BugReportRepository {
  abstract create(input: CreateBugReportInput): RepositoryResponse<BugReport>;
}
