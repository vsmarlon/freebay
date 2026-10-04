# Backend integration verification — 2026-10-01

## Identity and safety

- Branch/revision: `feat/production-hardening`, `c9808b106c3d53f07837542e93f25fd52c6bfbe5`.
- Windows; backend working tree was already dirty and preserved. Before running gates, whole-tree tracked diff SHA-256 was `b2cdcc1b2b1bd68896eb1fe385ed1581841f287355a42e1b2b6086e39ac95204`; `git status --short` SHA-256 was `b1b3af488602dd5d7c9d7b0222614dffae32f5af9ec831b537ec8f0f80c43ce7` (296 status lines). These fingerprints include unrelated user WIP; they are not clean-tree hashes.
- Test target inspected without recording credentials: `.env.test` resolves to PostgreSQL `localhost:5432/freebay_test_db` and Redis `localhost:6379`. The configured PostgreSQL and Redis TCP endpoints were reachable. `safe-prisma-db-push.js` permits only loopback, `freebay_test_db`, and ports 5432/5433; the test helpers also require `NODE_ENV=test` before cleanup.
- Integration and E2E scripts load `.env.test`, set `NODE_ENV=test`, and run the guarded schema sync. Both reported the database already in sync. No runtime `.env`, seed, migration, `db:sync`, or `db:seed` was run.
- Integration has `maxWorkers: 1`; integration setup checks the guarded DB and truncates test tables after each test. E2E also has `maxWorkers: 1`, and uses suite-owned fixtures. No live Stripe traffic is part of E2E (`setup-e2e.ts` supplies placeholder credentials when absent).
- The capture runner was reused from `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-baseline-run.cjs`. It redacts common connection strings/secrets. A separate scan found no credential-pattern matches in captured logs. Logs and JSON manifests are the complete gate evidence; manifests contain exact command, cwd, UTC timestamps, and exit code.
- No production source, tests, package configuration, or schema were edited for this verification. The pre-existing backend WIP remained in place. No branch, stash, commit, push, or migration action was performed.

## Gates

| Exact command (cwd `nest-backend`) | Result | Exit | Summary |
|---|---:|---:|---|
| `npx tsc --noEmit` | Pass | 0 | [`backend-typecheck.log`](backend-typecheck.log), [manifest](backend-typecheck.json) |
| `npm run lint` | Pass | 0 | [`backend-lint.log`](backend-lint.log), [manifest](backend-lint.json) |
| `npm test` | Pass | 0 | 99 suites, 614 tests; [`backend-unit.log`](backend-unit.log), [manifest](backend-unit.json) |
| `npm run build` | Pass | 0 | [`backend-build.log`](backend-build.log), [manifest](backend-build.json) |
| `npm run test:safety` | Pass | 0 | [`backend-safety.log`](backend-safety.log), [manifest](backend-safety.json) |
| `npm run test:integration` | Pass | 0 | 18 suites, 102 tests; guarded schema sync already in sync; [`backend-integration.log`](backend-integration.log), [manifest](backend-integration.json) |
| `npm run test:e2e` | Pass | 0 | 4 suites, 30 tests; guarded schema sync already in sync; [`backend-e2e.log`](backend-e2e.log), [manifest](backend-e2e.json) |

All seven backend gates passed. Expected error-path logging appeared in passing unit/integration tests; no gate failure or unrelated baseline blocker occurred. Jest noted a worker force-exit warning in the passing unit run; it did not change the exit status. These test-DB results do not establish production/runtime DB, live-provider, or device behavior.
