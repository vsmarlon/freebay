# Prisma runtime drift and test cleanup

Status: complete for the reported P2022 and the low-signal unit-test purge below.
No full application E2E result is claimed: the repo holds database integration
specs and a device matrix, but no automated app-level E2E suite yet. The new
smoke check is a real-database regression test, not an E2E run.

## Failure modes and test boundary (before the fix)

| Failure | Observable outcome | Required boundary |
| --- | --- | --- |
| Runtime database lacks transfer/reversal columns | Actual reconciliation query returns P2022/42703 | Real repository and the application's configured PostgreSQL database, before schema sync |
| Generated client and schema differ | Client validation/query fails or expected fields are absent | Regenerate from the canonical schema and repeat the same database query |
| Wrong environment is synchronized | Test DB passes while the runtime query still fails | Record actual database/schema identity separately for runtime and integration runs |
| Credentials or infrastructure are unavailable | Connection/setup error rather than the reported missing column | Mark verification blocked; do not count it as behavioral RED |
| A smoke test writes to the development database | Unintended data changes | PostgreSQL-enforced read-only connections; no fixtures or cleanup on this target |
| Mocks replace the broken query | Test passes while the real query fails | No substituted repository or Prisma delegate in the regression smoke |

The existing task spec mocks all three database operations. The integration runner synchronizes and cleans a different database. Neither can prove the runtime database is current. The new smoke reaches that gap without triggering seller payouts.

## Environment and reproduction

- Base revision: `85c6135bbfc6570ad99caed4d3412977dad47ad7` plus the inherited working tree and this task's changes. Final fingerprint and verification results follow below when complete.
- Windows / PowerShell 7, native PostgreSQL on `localhost:5432`.
- Approved runtime database: `postgres`, schema `public`; initial Transaction row count: 0.
- Isolated integration database: `freebay_test_db`; its configured credentials initially fail with PostgreSQL `28P01`.
- No runtime fixtures or reset are needed. The smoke reads existing data, exposes only database/schema identity, and uses PostgreSQL read-only connections.
- From `nest-backend`, run `npm run test:runtime-db -- --json --outputFile=../docs/test-runs/2026-09-25/runtime-db-red.json` before synchronization. Expected: nonzero exit with the actual repository query failing because Transaction.transferState is absent.
- Apply the approved fix with `npm run db:sync`, which pushes the canonical schema and regenerates the client.
- Repeat with `npm run test:runtime-db -- --json --outputFile=../docs/test-runs/2026-09-25/runtime-db-green.json`. Expected: exit 0 and the same query succeeds.
- Reproducing RED later requires a separate disposable database with the old schema. Do not remove columns from the synchronized development database.

## Results

### Runtime drift (RED → GREEN)

- Base revision `85c6135bbfc6570ad99caed4d3412977dad47ad7` plus the inherited
  working tree and this task's changes (500 changed paths; the app diff itself
  is untouched — only tests, docs, skills, and one `package.json` script).
- RED: `npm run test:runtime-db -- --json --outputFile=../docs/test-runs/2026-09-25/runtime-db-red.json`
  exited nonzero; the real `findTransferFailures` query failed with
  P2022/PostgreSQL 42703 (`Transaction.transferState` absent) against
  `postgres.public`. The database missed 11 transfer/reversal columns and both
  related enums. The mocked task spec passed throughout — it mocks all three
  database operations and cannot see this failure.
- Fix (approved target): `npm run db:sync` (`prisma db push --accept-data-loss`
  + `prisma generate`). Preflight: zero duplicate message-key groups, zero
  Transaction rows. `migrate diff --exit-code` now reports no difference.
- GREEN: same smoke command with `runtime-db-green.json` passes (exit 0).
  Full unit suite: 99 suites / 606 tests pass. `tsc:check`, `lint`
  (`--max-warnings 0`), `build`, `ci-check.js`, and `test:ci-scripts` pass.

### Test purge (14 files deleted, 10 files pruned)

Deleted — pure delegation with zero branches, mock-return echoes, DI
scaffolding, generated-code checks, or exact duplicates of verified broader
tests (`register` unit ≡ `register` integration spec; `comment` standalone ≡
`social.usecase.spec.ts` CommentUseCase block):

- `notifications/.../get-notifications.usecase.spec.ts`
- `notifications/.../register-fcm-token.usecase.spec.ts`
- `disputes/.../get-user-disputes.usecase.spec.ts`
- `social/.../like-comment.usecase.spec.ts` + `unlike-comment.usecase.spec.ts`
  (names claim atomic idempotency a mocked repo cannot establish)
- `social/.../comment.usecase.spec.ts` (redundant siblings, superseded)
- `bug-reports/.../create-bug-report.usecase.spec.ts`
- `auth/.../register.usecase.spec.ts` (superseded by the integration spec)
- `payments/.../transaction-repository-di.spec.ts`
- `users/.../account-lifecycle-repository-di.spec.ts`
- `admin/admin.controller.spec.ts`
- `frontend/test/widget_test.dart` (default smoke assertion)
- `frontend/test/features/payments/payment_intent_entity_test.dart`
  (pure `@freezed`/`json_serializable` checks)
- `frontend/test/features/auth/google_auth_usecase_test.dart`
  (pure delegation echoes)

Pruned — constant tautologies (`ACCOUNT_DELETION_GRACE_DAYS === 30`),
mock-echo-only tests, and error-passthrough echoes on read-only usecases
where the compiler already enforces the `Either` shape; kept every
authorization, money, concurrency, cursor-security, and recovery branch:

- `users.user.spec`: 6 echo/sequence tests (kept self-follow, not-found,
  already-following, unfollow, block/unblock branches)
- `consume-magic-link`, `cancel-account-deletion` (2),
  `request-account-deletion` (constant), `export-user-data`,
  `list-moderation-actions`, `list-reports`, `get-user-posts` (2),
  `create-story` specs; `cart_repository_test.dart` failure-mapping test
  (duplicates `request_either_test`).

Retained on purpose: all payment/webhook/checkout/payout specs (money,
idempotency, race handling), session/biometric/magic-link specs (token
security), guard/controller HTTP specs (cookies, Origin, route precedence,
webhook dispatch), cursor-forgery specs, media/upload traversal specs,
pagination/query-shaping specs, and pure-validator specs (CPF, URL safety,
error-message leak prevention). Flutter: 206/206 pass.

### Blocker follow-ups (all three fixed, plus two found along the way)

- Test database access: the `test` role did not exist (`28P01`). Created it
  and transferred the disposable `freebay_test_db` (database, schema,
  39 relations, 25 enum types) to that role — no production data touched.
  Also fixed the inherited `register` integration spec, which never
  registered `RegisterUseCase` in its module (`module.get` threw for all
  7 tests). Result: `test:integration` 17/17 (99 tests) green.
- Flutter analyzer infos: fixed the 3 (`const` constructor, `_` params).
  `flutter analyze --fatal-infos` is clean.
- Automated E2E: added `test/e2e/marketplace.journey.e2e-spec.ts` (full
  `AppModule` over HTTP + real test DB, 14 tests), `jest.config.e2e.js`,
  `test:e2e` script, and a CI step. Report:
  `docs/test-runs/2026-09-25/e2e-marketplace-journey.md` (`e2e-green.json`).
- Inherited cancel-reason refactor was incomplete (`tsc` red, `build` red
  in 7 places): completed with the nullable `cancellationReason` column
  (already in the schema, now synced), controller/usecase wiring, and an
  `Omit` seam keeping webhook refunds free of a meaningless required
  reason. Covered by two new journey tests.
- Inherited dialog rework had dropped `preventBack` (the `AppDialog`
  widget was bypassed; production session-expiry dialog relied on it) and
  title/button uppercase: restored both through the Cupertino path and
  fixed the 5 failing widget tests (dialog, router ×2, saved-posts ×2).
  Also fixed a stale `posts` mock key and replaced an obsolete Cancel test
  with a `Limpar` test for the new clear button.
- One full integration run showed 4 timeout failures in slow suites that
  pass in isolation and in the runs before/after — recorded as load flake,
  to be watched in CI.
