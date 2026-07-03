import { Injectable } from '@nestjs/common';
import { DisputeStatus } from '@prisma/client';

const TERMINAL_STATUSES: DisputeStatus[] = ['RESOLVED', 'CANCELLED'];

@Injectable()
export class DisputeTransitionPolicy {
  canResolve(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.includes(status);
  }

  canSubmitEvidence(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.includes(status);
  }

  canWithdraw(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.includes(status);
  }

  isOpener(dispute: { openedById: string }, userId: string): boolean {
    return dispute.openedById === userId;
  }
}
