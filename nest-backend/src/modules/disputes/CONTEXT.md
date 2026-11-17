# Disputes — Glossary

## Dispute

A `Dispute` is 1:1 with an `Order` (`orderId` is unique) — an order has at most one dispute row over its lifetime. It is opened by one of the two order participants (buyer or seller) and references them as `openedById`. A withdrawn dispute is reopened in place, so the one-row rule does not remove the opener's remedy.

## Dispute Status

```
                    evidence from the awaited party
  OPEN ───────────────────────────────────────────► AWAITING_SELLER ⇄ AWAITING_BUYER
    │                                                     (each submission flips)
    ├── escalation deadline ───► ESCALATED   (active, admin queue)
    ├── admin resolves ────────► RESOLVED    (terminal)
    └── opener withdraws ──────► CANCELLED   (reopenable)
```

`OPEN`, `AWAITING_SELLER`, `AWAITING_BUYER`, and `ESCALATED` are active states. An active dispute freezes escrow and blocks automatic release. `RESOLVED` is terminal. `CANCELLED` ends the attempt but can transition back to `OPEN` while the order is still disputable.

Every status change is a guarded write: the update names the expected current status, and zero rows updated is a conflict — never a silent overwrite.

## Opening Window

A dispute may only be **opened** within 48 hours of delivery confirmation. While the order is in handover (`SHIPPED`), no window applies because delivery has not been confirmed. Enforced in `usecases/open-dispute.usecase.ts`.

## Escalation Window

Once opened, a dispute has 72 hours (`expiresAt`, the escalation deadline) before it moves to `ESCALATED` and enters the admin queue. Escalation **never moves money**; it only makes the dispute visible for a human decision. There is no automatic seller-favor resolution. See [ADR-0003](docs/adr/0003-dispute-escalation-and-reopen.md).

## Withdraw and Reopen

The dispute's **opener** may withdraw it while it is active — not after it is `RESOLVED` or already `CANCELLED`. Withdrawal is **not a judgment on the merits**. It restores the order to its `preDisputeStatus` (the state it had before the dispute) with escrow still `HELD`, and moves no money. See [ADR-0002](docs/adr/0002-withdraw-dispute-restores-escrow-no-refund.md), amended by ADR-0003.

A withdrawn dispute may be reopened in place while the order is still `CONFIRMED`, `SHIPPED`, or `DELIVERED` and the opening window still holds. Reopening re-freezes escrow and returns the dispute to `OPEN`.

## Resolution

An admin resolves an active dispute in favor of the buyer or the seller. The outcome is persisted as `DisputeWinner { BUYER, SELLER }` with the note and the resolving admin. Buyer-favor refunds the buyer; seller-favor releases escrow and credits the seller's wallet. Both branches live in `services/dispute-resolution-execution.service.ts` so they cannot drift.

## Escrow Interaction

- `HELD` — no decision has been made; money is safely held.
- `RELEASED` — the seller won the resolution.
- `REFUNDED` — the buyer won the resolution.

## Wallet Balance Fields

When a dispute resolves in the seller's favor, `Wallet.pendingBalance` moves to `availableBalance` plus `totalEarned`. When it resolves in the buyer's favor, `availableBalance` is credited directly. This arithmetic lives in exactly one place — `services/dispute-resolution-execution.service.ts` — called by `ResolveDisputeUseCase`, so the two paths cannot drift apart.
