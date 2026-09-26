import { Injectable } from '@nestjs/common';
import { DisputeStatus } from '@prisma/client';

const TERMINAL_STATUSES = [DisputeStatus.RESOLVED, DisputeStatus.CANCELLED] as const;

@Injectable()
export class DisputeTransitionPolicy {
  canResolve(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.some((terminalStatus) => terminalStatus === status);
  }

  canSubmitEvidence(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.some((terminalStatus) => terminalStatus === status);
  }

  canWithdraw(status: DisputeStatus): boolean {
    return !TERMINAL_STATUSES.some((terminalStatus) => terminalStatus === status);
  }

  isOpener(dispute: { openedById: string }, userId: string): boolean {
    return dispute.openedById === userId;
  }
}
