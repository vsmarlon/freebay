import { BugReport } from '@prisma/client';
import { BugReportResponse } from '../dtos/bug-report.dto';

export function toBugReportResponse(bugReport: BugReport): BugReportResponse {
  return {
    id: bugReport.id,
    description: bugReport.description,
    createdAt: bugReport.createdAt,
  };
}
