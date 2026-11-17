import { Injectable } from '@nestjs/common';
import { DisputeStatus } from '@prisma/client';
import {
  DisputeParty,
  evidenceTarget,
  isActiveDisputeStatus,
} from '../domain/dispute-state';

@Injectable()
export class DisputeTransitionPolicy {
  canResolve(status: DisputeStatus): boolean {
    return isActiveDisputeStatus(status);
  }

  canSubmitEvidence(status: DisputeStatus, party: DisputeParty): boolean {
    return evidenceTarget(status, party) !== null;
  }

  canWithdraw(status: DisputeStatus): boolean {
    return isActiveDisputeStatus(status);
  }

  isOpener(dispute: { openedById: string }, userId: string): boolean {
    return dispute.openedById === userId;
  }
}
