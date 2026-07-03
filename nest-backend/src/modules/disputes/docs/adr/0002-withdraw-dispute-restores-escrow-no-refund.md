# ADR-0002: Dispute Withdrawal Restores Escrow to HELD, Never Refunds or Pays Out

**Status:** Accepted

## Context

Disputes can now be withdrawn by their opener (`WithdrawDisputeUseCase`), making the previously-dead
`DisputeStatus.CANCELLED` reachable. Two designs were considered for what withdrawal does to money:

1. **Treat withdrawal like a resolution** — moving money depending on who withdrew (buyer withdrawing implies
   a refund; seller withdrawing implies a release), mirroring `ResolveDisputeUseCase`'s buyer-win/seller-win
   branches.
2. **Treat withdrawal as "this dispute should not have affected money flow at all"** — restore
   `Order.escrowStatus` to `HELD` (no payout to anyone) and `Order.status` to `DELIVERED`, resuming the normal
   order lifecycle exactly as if the dispute had never been opened.

## Decision

(2) — withdrawal is not a judgment on the merits, it's the opener saying "I no longer want to contest this."
Money stays exactly where it was (in escrow) and the order resumes its normal path toward completion. Neither
party is paid out or refunded by the act of withdrawing.

## Alternatives considered and rejected

- **Buyer-favor refund on withdrawal:** rejected — it would let a buyer unilaterally extract a refund by
  opening then immediately withdrawing a dispute, bypassing the actual resolution process entirely.
- **Seller-favor release on withdrawal:** rejected for the same reason in reverse, and nonsensical when the
  opener is the seller (a seller "losing" money to themselves makes no sense).
- **Leaving `escrowStatus` untouched** (relying on it already being `HELD` by construction, since disputes can
  only be opened from `CONFIRMED`/`DELIVERED` orders — both pre-escrow-release states): functionally
  equivalent to the chosen decision under today's preconditions, but explicit restoration is more robust if a
  future change ever allows opening a dispute from a state where escrow isn't `HELD`.

## Consequences

- A withdrawn dispute's `resolution` field stays `null` — withdrawal is recorded via `status: CANCELLED` and
  `resolvedAt`, not a resolution string, since no decision was made. Don't conflate the two when reading dispute
  history.
- This is a real money-handling policy baked into a wallet-mutation-free code path. Reversing it later means
  deciding how to handle previously-withdrawn disputes under the old semantics versus a new one — a migration
  question, not just a code change.
- A future reader skimming `WithdrawDisputeUseCase` might expect it to behave like `CancelOrderUseCase`
  (`modules/orders/usecases/order.usecase.ts:256-299`, which *does* refund the buyer) or like
  `ResolveDisputeUseCase`'s buyer-win branch (also moves money) — both existing precedents in this codebase.
  Withdrawal deliberately does neither.
