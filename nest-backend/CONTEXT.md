# CONTEXT — `effect`-based integration test pilot (Disputes module)

> Status: Accepted — see [ADR-0001](src/modules/disputes/docs/adr/0001-effect-ts-integration-tests.md). Implemented
> in `src/modules/disputes/usecases/dispute.integration-spec.ts` + `src/modules/disputes/effect-harness/`.
> Scope: `nest-backend/src/modules/disputes/` only.
> Goal: Replace heavily-mocked Jest specs with real-DB, TDD-driven integration tests using `effect` (Effect-TS) for dependency composition and deterministic time control.
>
> This document's original proposal (below) is kept as historical context for the rationale and the
> behavior table. The actual domain glossary for Disputes lives at
> [src/modules/disputes/CONTEXT.md](src/modules/disputes/CONTEXT.md) — this file is a testing-strategy
> decision record, not a glossary.

---

## Why this matters

Current unit tests (`dispute.usecase.spec.ts`) mock `PrismaService` via `jest.mock` + `useValue`. They verify "did I call the mock correctly," not real behavior — a mock `$transaction` callback that returns hardcoded values never exercises the actual Prisma query engine, foreign-key constraints, or wallet balance arithmetic.

The existing integration test setup (`npm run test:integration`, `jest.config.integration.js`, `test/setup-integration.ts`) hits a real Postgres via `.env.test` + `prisma db push --accept-data-loss`, but:
- It's not the default test target — devs reach for `npm test` (unit), so integration coverage stays thin.
- Time-dependent logic (48h dispute window, 72h auto-expiry) is tested with `jest.useFakeTimers` or not tested at all — both are flaky or skipped.
- There's no way to compose *real* DB access with *fake* side effects (notifications, FCM) at the type level.

---

## What `effect` gives us

| Concern | Current approach | `effect` approach |
|---|---|---|
| Dep composition | `Test.createTestingModule` + `useValue` mocks | `Layer.merge(LivePrisma, TestNotifications)` — typed, explicit, composable |
| Deterministic time | `jest.useFakeTimers` / not tested | `TestClock.adjust("48 hours")` — advance virtual time exactly, assert boundaries |
| Error channels | `Either<AppError, T>` (manual) | `Effect<T, E, R>` — adds `R` (requirements) so deps are tracked at the type level |
| Structured concurrency | ad-hoc `Promise.all` inside `$transaction` | `Effect.all` with interruption, supervision, retry policies |

The migration path is **not** "rip out Either everywhere." Pilot on one bounded context (Disputes), wrap Prisma/Notification in `Context.Tag`, keep the usecase's public return type as `Either` so controllers don't change.

---

## Existing test infrastructure (reuse this)

- **`jest.config.integration.js`** — `maxWorkers: 1`, matches `*.integration-spec.ts`, 30s timeout, runs `setup-integration.ts` before tests
- **`test/setup-integration.ts`** — connects `PrismaClient` against `.env.test`, checks `NODE_ENV=test` + `freebay_test` DB, truncates all tables in `afterEach` (ordered by FK constraints)
- **`.env.test`** — DATABASE_URL pointing to `freebay_test` Postgres; REDIS_URL for cache
- **`npm run test:integration`** — runs `prisma db push --accept-data-loss` then Jest

Do NOT invent a new DB setup. The `effect`-based tests should reuse this — either by importing the shared `prisma` from `test/setup-integration.ts` or by wrapping the `PrismaClient` in an Effect `Layer` that connects once per suite.

---

## Current dispute module structure

```
src/modules/disputes/
├── dtos/dispute.dto.ts            # Input/output types
├── disputes.controller.ts         # HTTP handlers
├── disputes.module.ts             # NestJS module
└── usecases/
    ├── open-dispute.usecase.ts    # 48h window check (Date.now())
    ├── resolve-dispute.usecase.ts # Wallet mutation, NO status guard
    ├── submit-evidence.usecase.ts # Status transitions
    ├── get-dispute.usecase.ts     # Read
    ├── get-user-disputes.usecase.ts # List
    └── dispute.usecase.spec.ts    # ALL current tests (heavily mocked)
```

Dependencies injected into dispute usecases:
- **`PrismaService`** (`src/shared/infra/prisma/prisma.service.ts`) — extends `PrismaClient`, wraps pg Pool + adapter
- **`NotificationService`** (`src/modules/notifications/services/notification.service.ts`) — calls `this.prisma.notification.create()` + `this.fcm.sendNotification()` (has real side effects — FCM push)

---

## Known bugs / gaps to uncover with real tests

### 1. ResolveDisputeUseCase — missing status guard (BUG)
`resolve-dispute.usecase.ts:24-65` has no check on `dispute.status`. Calling `execute()` on an already-RESOLVED dispute:
- Applies wallet mutations again (double-increment buyer balance or double-release seller funds)
- The `$transaction` succeeds silently because there's no `where: { status: { not: "RESOLVED" } }` guard

**Test should:** 1st call succeeds with wallet changes, 2nd call is rejected, wallet balances are NOT double-applied.

### 2. OpenDisputeUseCase — 48h boundary uses real `Date.now()`
`open-dispute.usecase.ts:39` compares `Date.now()` against `deliveryConfirmedAt`. In unit tests, this is unfakeable without `jest.useFakeTimers`. With `TestClock`, you can:
- Set `deliveryConfirmedAt` to `TestClock.currentTime - 47h59m` → dispute opens
- Set `deliveryConfirmedAt` to `TestClock.currentTime - 48h01m` → dispute rejected

### 3. Auto-expiry cron duplicates resolve-dispute wallet logic
`dispute-cleanup.task.ts:22-50` duplicates the seller-win wallet mutation from `resolve-dispute.usecase.ts`. If the resolve logic changes (e.g., fee deduction), the cron will drift. Flag this — don't necessarily fix in this pass unless asked.

### 4. SubmitEvidence — status transitions
`submit-evidence.usecase.ts` transitions `OPEN → AWAITING_SELLER` (buyer submits) or `OPEN → AWAITING_BUYER` (seller submits) but doesn't guard against:
- Submitting when status is already `AWAITING_*` (should be accepted as overwrite? or rejected?)
- Submitting after `RESOLVED` (should be rejected)

---

## What to build

### 1. Effect harness in `src/modules/disputes/` (local, not shared)

```
src/modules/disputes/
├── effect-harness/
│   ├── tags.ts              # Context.Tag<PrismaService> and Context.Tag<NotificationService>
│   ├── live-prisma.layer.ts # Layer that connects Prisma against .env.test
│   └── test-notifications.layer.ts  # Layer that records calls (spy array) instead of firing FCM
```

Keep it local to disputes. Only promote to `src/shared/infra/effect/` if a second module adopts the pattern — justify with concrete duplication.

### 2. Integration specs (TDD, red-green-refactor)

File: `src/modules/disputes/usecases/dispute.effect-integration-spec.ts`

For each behavior:
1. Write the failing test against real DB + `TestClock` → run → confirm failure reason
2. Implement the minimal usecase change
3. Refactor

Behaviors (in order):

| # | Behavior | Usecase | Test assertions |
|---|----------|---------|-----------------|
| a | Open dispute at 47h59m succeeds | `open-dispute` | Dispute row created, Order.status = DISPUTED, notifications recorded |
| b | Open dispute at 48h01m is rejected | `open-dispute` | `left(BadRequestError)`, no DB mutation |
| c | Resolve dispute twice — 2nd call rejected | `resolve-dispute` | 1st: wallet updated; 2nd: `left(BadRequestError)`; wallet balances NOT double-applied |
| d | Auto-expiry resolves in seller's favor | `dispute-cleanup.task` | Dispute.status = RESOLVED, Order.escrowStatus = RELEASED, seller wallet updated |
| e | SubmitEvidence flips status correctly | `submit-evidence` | Buyer submits → AWAITING_SELLER; Seller submits → AWAITING_BUYER; non-participant rejected |

### 3. Driving tests with Effect

```typescript
// Pattern for each test:
it('should reject open dispute after 48h window', async () => {
  const program = Effect.gen(function* () {
    const prisma = yield* PrismaTag;
    // seed order with deliveryConfirmedAt = now - 48h01m
    yield* prisma.order.create({ ... });
    // advance clock past boundary
    yield* TestClock.adjust("48 hours 1 minute");
    // execute
    const result = yield* Effect.promise(() =>
      openDisputeUseCase.execute({ orderId, userId, reason })
    );
    // assert
    assert.ok(isLeft(result));
    // verify no dispute row was created
    const dispute = yield* Effect.promise(() =>
      prisma.dispute.findUnique({ where: { orderId } })
    );
    assert.strictEqual(dispute, null);
  });

  await Effect.runPromise(
    program.pipe(
      Effect.provide(Layer.merge(LivePrismaLayer, TestNotificationsLayer))
    )
  );
});
```

---

## Constraints

1. **Do NOT change controller signatures** (`disputes.controller.ts`) — they call usecases with `await`, get back `Either`. Route adapter handles the `left`/`right` branching.
2. **Do NOT replace Either project-wide** — keep `Either<AppError, T>` as the public return type of each usecase. Effect is at the test/dependency layer, not the API boundary.
3. **Do NOT add `effect` to NestJS DI** — don't mix Effect's `Context` with NestJS's `Module` providers. The `Layer`s instantiate PrismaService directly (or wrap the existing `PrismaClient` from `test/setup-integration.ts`). No `@nestjs/common` decorators needed in the harness.
4. **No comments explaining WHAT code does** — only add comments for non-obvious WHY (e.g., "TestClock. adjust instead of real timers to avoid 48h test wall-clock wait").
5. **Keep efiles inside `src/modules/disputes/`** unless genuinely shared — harness goes in `disputes/effect-harness/`, not `shared/`.
6. **If `effect` introduces type friction with Either** (e.g., `Effect<A, E, R>` vs `Promise<Either<L, R>>`), surface it explicitly — don't use `as any`.

---

## Dependency checklist before starting

- [ ] `effect` is NOT in `package.json` — add `effect` (latest stable) as a dependency
- [ ] `@effect/schema` and `@effect/platform` are optional — only pull them if schema validation or HTTP interfaces are needed (probably not for this pilot)
- [ ] Check `tsconfig.json` for `strict: true` (already is per AGENTS.md) — Effect-TS requires strict mode
- [ ] Verify `jest.config.integration.js` can transpile Effect-TS — Effect uses `Data` and tagged unions extensively; `ts-jest` with `tsconfig: 'tsconfig.json'` should handle it

---

## Generalization notes (for the summary)

After the pilot is green, evaluate what generalizes:

| Aspect | Disputes-specific | General |
|--------|------------------|---------|
| Time-dependent state machine | 48h/72h boundaries, AWAITING_* states | Any module with expiration, cooldowns, or time windows (Orders.cancelWindow, Payments.refundPeriod) |
| Wallet mutations | Resolve dispute credits buyer/seller | Payments release, Withdrawal confirm — same balance arithmetic, real DB needed |
| Notification recording | Dispute uses notifyDispute + notifyOrderStatus | Generic pattern: spy Layer for any side-effect dependency (FCM, email, webhook) |
| Cron with DB query | DisputeCleanupTask queries expired disputes | Any cron that reads DB + mutates state (order cleanup, payment expiry) |
| Layer composition | LivePrisma + TestNotifications | Same pattern for every module — just swap the Context.Tag definitions |
| TestClock | Boundary assertion on dispute window | Any module with date math — orders, escrow, subscription billing |

The main thing that *doesn't* generalize: dispute's specific state machine (OPEN → AWAITING_SELLER/AWAITING_BUYER → RESOLVED) and its exact wallet credit logic. Every other pattern — Layer composition, TestClock, spy services, real-DB assertions — is reusable as-is.
