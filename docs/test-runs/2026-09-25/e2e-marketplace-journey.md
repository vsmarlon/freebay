# E2E marketplace journey — repeatable artifact

Status: green. Full `AppModule` over real HTTP against the real test database
(`freebay_test_db`), with real guards, pipes, interceptors, usecases, and
repositories. Suite: `nest-backend/test/e2e/marketplace.journey.e2e-spec.ts`
(`jest.config.e2e.js`, `npm run test:e2e`, wired into the `backend-ci`
workflow after the integration step).

## Failure modes and boundary (written before the fix)

| Failure | Observable outcome | Boundary |
| --- | --- | --- |
| Unauthenticated access to protected routes | 401, no data leaked | Real `JwtAuthGuard` over HTTP |
| Wrong password / duplicate email | 401 `INVALID_CREDENTIALS` / 409 `EMAIL_ALREADY_EXISTS` | Real auth usecases + real DB |
| Invalid money input | 400 `VALIDATION_ERROR` via the global pipe | Real validation pipe over HTTP |
| Buyer/seller confusion | Order rejected or forbidden | Real ownership checks over HTTP |
| Cancel without a reason | 400 `VALIDATION_ERROR`, order untouched | Real `CancelOrderDTO` over HTTP |
| Lost audit reason | `cancellationReason` NULL after cancel | Real column read back from the DB |
| External calls in the journey | Stripe/FCM/email traffic | Out of scope by construction: the journey never calls them (FCM disables itself without credentials; Stripe keys are placeholders and the provider is never invoked) |

## What the suite caught while going red

- Login returns 200, not 201 — pinned as the actual contract.
- `UserResponse` carries no `email` (privacy by design) — assertions corrected.
- `POST /products` returns product scalars without `images` — image persistence
  is verified through `GET /products/:id` instead.
- The inherited cancel-reason refactor was incomplete (`tsc` red, `build`
  red): completed with a nullable `cancellationReason` column (already in the
  schema, now synced), controller/usecase wiring, and an `Omit` seam keeping
  webhook refunds free of a meaningless required reason. Covered by two new
  journey tests (cancel with reason persists; cancel without reason is
  rejected and leaves the order cancellable).

## Environment and reproduction

- Windows / PowerShell 7, native PostgreSQL `localhost:5432`, local Redis.
- Test database `freebay_test_db` owned by the `test` role (created during
  this task; previously the role did not exist — `28P01`).
- `cd nest-backend && npm run test:e2e` (syncs the test schema, then runs the
  journey serially). JSON evidence: `e2e-green.json` in this directory.
- Each run uses unique emails/usernames/slugs; the suite truncates once in
  `beforeAll`. Uploaded product images are removed in `afterAll`.
- Throttling is production-configured; requests are paced 150ms so a 429
  would fail loudly rather than flake.

## Results

- `test:e2e`: 14/14 pass (`e2e-green.json`, exit 0).
- `npm test`: 99 suites / 606 pass. `test:integration`: 17/17 (99 tests) pass
  on the final run; one earlier full run showed 4 timeout failures in slow
  suites that pass in isolation and in the runs before/after — recorded as
  load flake, to be watched in CI.
- `tsc --noEmit --incremental false`, `lint --max-warnings 0`, `build`,
  `flutter analyze --fatal-infos`, `flutter test` (206/206), `ci-check.js`,
  `test:ci-scripts`: all pass.
