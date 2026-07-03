# Disputes — Glossary

## Dispute

A `Dispute` is 1:1 with an `Order` (`orderId` is unique) — an order can have at most one dispute over its
lifetime. It's opened by one of the two order participants (buyer or seller) and references them as
`openedById`.

## Dispute Status

```
        submit evidence           submit evidence
  OPEN ───────────────────► AWAITING_SELLER ◄────────────────┐
   │  ▲                            │                          │
   │  └────────────────────────────┘                          │
   │         submit evidence (either direction, repeatable)    │
   │                                                            │
   ├──────────────────────► AWAITING_BUYER ────────────────────┘
   │
   ├─── admin resolves ───► RESOLVED        (terminal)
   │
   └─── opener withdraws ─► CANCELLED       (terminal)
```

`OPEN`, `AWAITING_SELLER`, and `AWAITING_BUYER` are all active states — evidence submission moves between them.
`RESOLVED` and `CANCELLED` are both terminal: no transition leaves either one. This is enforced in code by
`services/dispute-transition.policy.ts`, which every status-changing usecase (`ResolveDisputeUseCase`,
`SubmitEvidenceUseCase`, `WithdrawDisputeUseCase`) consults before mutating a dispute.

## Resolution Window

A dispute may only be **opened** within 48 hours of delivery confirmation (falling back to the order's
creation time if delivery was never explicitly confirmed). Enforced in `usecases/open-dispute.usecase.ts`.

## Expiry Window

Once opened, a dispute has 72 hours to be resolved. If nobody (admin) resolves it in that window,
`DisputeCleanupTask` (a cron job in `modules/tasks/dispute-cleanup.task.ts`, running every 30 minutes)
auto-resolves it in favor of the seller. **This is an existing, intentional business rule** — documented here,
not changed by the work that introduced this glossary.

## Withdraw

The dispute's **opener** may withdraw it at any point while it's still active (`OPEN`, `AWAITING_SELLER`, or
`AWAITING_BUYER`) — not after it's `RESOLVED` or already `CANCELLED`. Withdrawal is **not a judgment on the
merits**: it doesn't favor either party. It restores the order to its pre-dispute state (`DELIVERED`, escrow
`HELD`) and resumes the normal order lifecycle, as if the dispute had never been opened. See
[ADR-0002](docs/adr/0002-withdraw-dispute-restores-escrow-no-refund.md) for why this doesn't move any money.

## Escrow Interaction

- `HELD` — the default state, and what withdrawal restores. Money is safely held, no decision has been made.
- `RELEASED` — happens when the seller wins a resolution, or when a dispute auto-expires (seller-favor default).
- `REFUNDED` — happens when the buyer wins a resolution.

## Wallet Balance Fields

When a dispute resolves in the seller's favor (admin decision or auto-expiry), `Wallet.pendingBalance` moves to
`availableBalance` plus `totalEarned`. When it resolves in the buyer's favor, `availableBalance` is credited
directly. This arithmetic lives in exactly one place —
`services/dispute-resolution-execution.service.ts` — called by both `ResolveDisputeUseCase` and
`DisputeCleanupTask`, so the two paths can't drift apart.
