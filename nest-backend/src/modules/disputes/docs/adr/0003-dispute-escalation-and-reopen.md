# ADR-0003: Dispute escalation, reopen, and pre-dispute restore

**Status:** Accepted (2026-11-09). Supersedes the 72-hour seller-favor rule in
`disputes/CONTEXT.md` and amends ADR-0002.

## Context

`disputes/CONTEXT.md` documented that an unresolved dispute auto-resolves in
favor of the seller after 72 hours. `DisputeCleanupTask` only logs
`"remains held for manual review"`; it never moves money. With no admin UI,
the documented rule was both unimplemented and unobservable.

Withdrawal has the same documentation/code gap: ADR-0002 says withdrawal
restores the order to `DELIVERED`, but a dispute can be opened from
`CONFIRMED` or `SHIPPED`, where forcing `DELIVERED` invents a delivery that
never happened and leaves `deliveryConfirmedAt` null.

Finally, `@unique` on `Dispute.orderId` combined with "reject if any row
exists" made a withdrawn dispute remove the opener's only remedy for the rest
of the order's life.

## Decision

- **Escalate, do not auto-resolve.** When `expiresAt` (the escalation deadline)
  passes, an active dispute moves to the new `ESCALATED` status. It stays
  active — escrow remains frozen and automatic release stays blocked — and it
  appears in the admin queue. No money moves on escalation.
- **Record the winner.** Add `DisputeWinner { BUYER, SELLER }`, persisted on
  resolution with the note and the resolving admin. The free-text `resolution`
  is not a substitute for the outcome.
- **Reopen in place.** `CANCELLED -> OPEN` is allowed while the order is still
  `CONFIRMED`, `SHIPPED`, or `DELIVERED` and the opening window still holds.
  Reopening re-freezes escrow. The one-row-per-order invariant stays; no
  partial unique index is required.
- **Restore the pre-dispute state.** Add `Order.preDisputeStatus`, written when
  the dispute opens and restored on withdrawal. ADR-0002's money decision
  (withdrawal moves no money; escrow returns to `HELD`) is unchanged; only its
  claim that the order always returns to `DELIVERED` is corrected.
- **Turn-taking is enforced.** Only the party the dispute is waiting on may
  submit evidence, and each submission flips the waiting party. Submission is
  a guarded write, not a read-then-write.

## Consequences

- The admin queue is the SLA. If nobody staffs it, funds stay frozen — which is
  already today's behavior, now visible instead of silent.
- Escalation and admin resolution must be covered by the same audit trail as
  report moderation.
- `disputes/CONTEXT.md` is rewritten to match. There is no data migration for
  the retired auto-seller path because it never executed; verify no dispute
  was resolved by the cron before deleting the rule.
