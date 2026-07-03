# ADR-0001: Effect-TS for Disputes Integration Testing

**Status:** Accepted

## Context

The Disputes module's correctness depends on real Postgres behavior (foreign-key constraints, transactional
atomicity) and on precise time-boundary logic (the 48h dispute-opening window, the 72h auto-expiry window).
Mocked `PrismaService` unit tests verify "did I call the mock correctly," not real behavior — a mocked
`$transaction` callback that returns hardcoded values never exercises the actual Prisma query engine or FK
constraints. `jest.useFakeTimers` is the conventional alternative for the time-boundary cases, but it's flaky
and awkward to reason about across async transaction boundaries.

Two designs were considered:
1. Keep all Disputes tests as mocked Jest unit specs, accepting the coverage gap on real-DB/FK/transaction
   behavior, and use `jest.useFakeTimers` for the time-boundary cases.
2. Pilot Effect-TS (`effect` package) for this one module: `Layer`-composed dependencies (`PrismaTag`,
   `NotificationTag`) running against a real test Postgres, with `TestClock` for deterministic time control,
   replacing the mocked unit specs for the usecases where this matters most.

## Decision

(2) — adopt Effect-TS-based real-DB integration tests for Disputes' time-sensitive and state-transition-
sensitive usecase behaviors (`OpenDisputeUseCase`'s 48h window, `ResolveDisputeUseCase`'s idempotency guard,
`SubmitEvidenceUseCase`'s status transitions, `DisputeCleanupTask`'s auto-expiry, `WithdrawDisputeUseCase`'s
state guards). They live in `usecases/dispute.integration-spec.ts`, run via the existing
`jest.config.integration.js` / `npm run test:integration` infra against a real test Postgres.

Plain Jest unit specs remain the right tool for logic that doesn't benefit from a real DB or deterministic
time: the pure `DisputeTransitionPolicy` (zero IO), the extracted `DisputeResolutionExecutionService` (tested
against a fake `tx` object, since it's the mutation logic under test, not transaction mechanics), and the
remaining trivial reads (`GetDisputeUseCase`, `GetUserDisputesUseCase`).

## Consequences

- Disputes is the only module in this codebase using Effect-TS for its tests — a deliberate inconsistency,
  not a project-wide migration. If this pattern proves valuable, it can be extended to other modules with
  similar time-window or multi-step-transaction logic (e.g. Orders' cancellation window, Payments' refund
  period) — but that's a future decision, not implied by this one.
- The Effect harness (`effect-harness/{tags.ts, live-prisma.layer.ts, test-notifications.layer.ts, index.ts}`)
  is local to `modules/disputes/` and should only be promoted to `shared/infra/effect/` if a second module
  adopts the same pattern, justified by concrete duplication — not preemptively.
- `effect` is a new runtime dependency, scoped to test code only — it is not used in any production usecase
  or controller. The public usecase contract is unchanged: `Either<AppError, Output>`.
