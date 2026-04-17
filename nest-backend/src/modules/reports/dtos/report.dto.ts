import { z } from 'zod';
import { Report, ReportReason } from '@prisma/client';

export const createReportSchema = z.object({
  targetType: z.enum(['USER', 'POST']),
  targetId: z.string().uuid(),
  reason: z.string().min(1),
  description: z.string().optional(),
});

export type CreateReportInput = z.infer<typeof createReportSchema> & {
  reporterId: string;
};

export interface GetReportsInput {
  status?: string;
}

export interface ResolveReportInput {
  reportId: string;
  status: 'REVIEWED' | 'RESOLVED' | 'REJECTED';
  adminNote?: string;
}

export interface ResolveReportOutput {
  resolved: boolean;
}

export interface ReportWithRelations {
  id: string;
  reason: ReportReason;
  description: string | null;
  status: Report['status'];
  createdAt: Date;
  reporterId: string;
  reportedUserId: string | null;
  reportedPostId: string | null;
}
