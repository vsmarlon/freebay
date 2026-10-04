# UX2 close-friends candidate search regression

- Tested revision: `c9808b106c3d53f07837542e93f25fd52c6bfbe5` plus the integrated dirty working tree. The repository already had extensive unrelated dirty work. Initial hashes and test logs are retained beside this report.
- Owned code changes: one nested search-filter fragment in `safety-list-database.repository.ts` and extension of the existing `allows either connection direction and revokes only after the final edge is lost` HTTP/Prisma E2E case. This E2E validates a matching outsider is excluded, following/follower candidates both remain searchable, selected+search filtering, and limit/offset 0/1/2 with stable order. Initial test fixture uses one edge per candidate; it restores the second edge before the pre-existing revocation checks. Existing privacy/media/revocation assertions remain.
- Environment: the repository's guarded E2E/integration commands reported PostgreSQL database `freebay_test_db`, schema `public`, localhost:5432. No credentials recorded. No schema file/package/config change was made. No Flutter/device/runtime DB command was run.
- RED: `npm run test:e2e -- --runTestsByPath test/e2e/story-audience.e2e-spec.ts -t "allows either connection direction"` — exit 1, intended assertion failed because the matching outsider was returned (1 failed, 4 skipped). `red-e2e.log`.
- Focused GREEN: same command — exit 0, 1 passed, 4 skipped. `green-focused.log`.
- Story suite: `npm run test:e2e -- --runTestsByPath test/e2e/story-audience.e2e-spec.ts` — exit 0, 5 passed. `green-story-suite.log`.

## Backend gates

Commands ran sequentially from `nest-backend` after the focused suite:

| Command | Exit | Result |
|---|---:|---|
| `npx tsc --noEmit` | 0 | Passed |
| `npm run lint` | 0 | Passed |
| `npm test` | 0 | 99 suites, 614 tests passed |
| `npm run build` | 0 | Passed; backend build completed for the parallel fixture agent |
| `npm run test:safety` | 0 | 5 passed |
| `npm run test:integration` | 1 | 6 suites passed, 12 failed; PostgreSQL test DB entered recovery under integration load (`57P03`, `Connection terminated unexpectedly`). See `gate-integration.log`. |
| `npm run test:e2e` | 1 | Guarded test-schema sync refused to proceed because PostgreSQL reported recovery had not reached a consistent state. See `gate-e2e.log`. |

The integration failure was environmental/test-database availability, not a green gate. No retry or manual DB recovery was attempted. The focused real-HTTP/Prisma E2E and the complete story-audience suite both passed before that failure.

## Evidence files

Each command has a redacted `.log` and exact command/timestamp/exit `.json` from `freebay-baseline-run.cjs`. `initial-state.txt` records the base revision and hashes of the touched-area files/config/schema before the owned edits. `test-red.patch.txt` records the pre-production test diff (including pre-existing dirty changes in that file); the working-tree diff must be distinguished from this session's owned increment above.
