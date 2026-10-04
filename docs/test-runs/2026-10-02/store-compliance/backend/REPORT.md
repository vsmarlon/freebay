# Apple auth deletion-race verification

**Revision:** `c9808b1` plus dirty working-tree changes; no commit or staging performed.
**Environment:** Local Windows workspace, credentials not recorded. Unit tests use Nest testing mocks; no database, migration, schema sync, provider, or device was used.

## Change and contract

Apple sign-in may find an active account, then race with its deletion before credential rotation. Rotation updates only `{ id, deletedAt: null }`; only Prisma `P2025` no-match becomes a `null` result and an ordinary removed-account auth rejection. Unexpected repository failures remain `DatabaseError`s, and the use case does not issue a session for no-match or a returned deleted user. The general `users.update` path is unchanged. Pending-deletion accounts with `deletedAt: null` remain eligible for reauthentication to cancel deletion.

## RED → GREEN

- RED command: `npm test -- --runInBand src/modules/auth/usecases/apple-auth.usecase.spec.ts` (from `nest-backend`). Exit 1; the race regression observed a Right result/session where a Left was expected. The existing Apple sign-in assertion also failed because it expected the old generic update operation.
- GREEN command: `npm test -- --runInBand src/modules/auth/usecases/apple-auth.usecase.spec.ts src/modules/auth/data/repositories/user-database.repository.spec.ts` (from `nest-backend`). Exit 0; 2 suites, 9 tests passed.
- RED and GREEN logs: `C:\Users\Qiyana\AppData\Local\Temp\opencode\apple-auth-red.log` and `C:\Users\Qiyana\AppData\Local\Temp\opencode\apple-auth-green.log`.
- Follow-up P2025 RED: `npm test -- --runInBand src/modules/auth/data/repositories/user-database.repository.spec.ts` (from `nest-backend`), with the old no-match behavior restored temporarily. Exit 1 as intended: P2025 became `DatabaseError` instead of `Right(null)`; 1 suite, 1 regression failed, 2 tests passed. Log: `C:\Users\Qiyana\AppData\Local\Temp\opencode\apple-auth-p2025-red.log`.
- Follow-up GREEN command: `npm test -- --runInBand src/modules/auth/data/repositories/user-database.repository.spec.ts src/modules/auth/usecases/apple-auth.usecase.spec.ts src/shared/auth/apple-provider.service.spec.ts src/modules/users/usecases/request-account-deletion.usecase.spec.ts src/modules/users/usecases/cancel-account-deletion.usecase.spec.ts` (from `nest-backend`). Exit 0; 5 suites, 41 tests passed. Log: `C:\Users\Qiyana\AppData\Local\Temp\opencode\apple-auth-p2025-green.log`.

## Gates

- `npx tsc --noEmit` — exit 0.
- `npm run lint` — exit 0.
- `npm run build` — exit 0.
- `npm run test:safety` — exit 0; 5 tests passed.
- `npm test -- --runInBand` — initial fix run exit 0; 103 suites, 646 tests passed. Expected repository error logging was emitted by mocked unexpected-failure coverage.
- Post-P2025 reruns: `npx tsc --noEmit`, `npm run lint`, `npm run build`, and `npm run test:safety` each exited 0.
- Final post-fix `npm test -- --runInBand` — exit 0; 103 suites, 648 tests passed.
- Final focused rerun (five suites above) — exit 0; 5 suites, 41 tests passed, including the exact `INVALID_APPLE_TOKEN` result and no session on P2025.
- No integration/E2E tests were run: no authorized/configured external PostgreSQL and Redis environment; no DB setup or mutation was permitted.

## Scope limit

The existing account-lifecycle cron and purge implementation were deliberately left untouched. The scheduled purge remains destructive/unresolved; this fix does not make it non-destructive, safe, or complete. Media deletion, revocation changes, schema changes, and database operations are out of scope.

## Independent verification

- Added `apple-auth.usecase.spec.ts` coverage that pending deletion (`deletionRequestedAt` set, `deletedAt` null) remains eligible for Apple reauthentication; this preserves the route needed to cancel deletion. The existing suite had no such explicit regression.
- Focused command (from `nest-backend`): `npm test -- --runInBand src/modules/auth/usecases/apple-auth.usecase.spec.ts src/modules/auth/data/repositories/user-database.repository.spec.ts src/shared/auth/apple-provider.service.spec.ts src/modules/users/usecases/request-account-deletion.usecase.spec.ts src/modules/users/usecases/cancel-account-deletion.usecase.spec.ts` — exit 0; 5 suites and 40 tests passed.
- Expected mocked Prisma no-match logging appeared during repository coverage (`Error: Record not found`); the suite passed. No provider, database, or HTTP boundary was exercised.
- Existing specs collectively cover Apple provider token verification/encryption, race rejection, conditional persistence predicate and no-match failure, plus pending-deletion request/cancel and fresh-auth requirements. No production defect was exposed by this verification.

## P2025 status normalization follow-up

The review follow-up narrows Prisma `P2025` to the expected no-active-row case (`Right(null)`), which Apple auth maps to the existing `INVALID_APPLE_TOKEN` rejection; unexpected database failures remain left as `DatabaseError`. Post-update-to-session race coverage remains outside this fix, as noted by the independent security review. Final gates passed as recorded above.
