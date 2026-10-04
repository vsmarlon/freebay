# Profile identity verification — backend RED

## Evidence identity

- Repository: `C:\Users\Qiyana\Documents\GitHub\ME\freebay`
- HEAD at run: `c9808b106c3d53f07837542e93f25fd52c6bfbe5`; tree was shared/dirty. This lane added only `nest-backend/test/e2e/profile-identity.e2e-spec.ts` and this evidence directory.
- Guarded environment: `NODE_ENV=test`; safe URL validation passed; live Prisma query returned database `freebay_test_db`, schema `public`. Credentials/URLs/tokens, fixture email, and CPF are omitted. No non-test DB was queried.
- The root `AGENTS.md`, `FEATURE_TRUTH.md`, `HARDENING_PLAN.md`, backend/test-audit skills, `CAMPAIGN.md`, Prisma/data-model skills, schema, E2E config/setup/helpers and existing controller/use case were read. `nest-backend/AGENTS.md` does not exist in this checkout.

## Test contract and ownership

- **Observable contract:** an owner making an authenticated `PATCH /users/me` with a valid CPF change and no verification proof receives HTTP 403 with `PROFILE_VERIFICATION_REQUIRED`.
- **Credible regression:** today’s endpoint passes the valid CPF through `UpdateProfileUseCase` to the database without verification. The guard must block it before the identity field changes.
- **Why stronger existing coverage misses it:** current profile DTO/use-case coverage does not exercise authenticated HTTP, auth guards, global validation/exception/response handling, and persistence together for sensitive identity updates. This is one real HTTP/Postgres test; no test-only production seam is added.
- **Fixture:** existing `POST /auth/register` path creates an owner and JWT; valid synthetic CPF input; one request only. No payment or Stripe operation. Existing guarded `cleanDatabase` lifecycle is used. An explicit current database/schema query runs after `assertSafeTestEnvironment` and before cleanup.
- **Future proof expectations are not implemented here.** The test owns only the specified unauthorized-change RED; no future classes, endpoint, verification flow, schema or production code were introduced.

## RED result

The exact guarded command completed the current database schema sync against only `freebay_test_db/public`, started the Nest app, registered the fixture owner, and sent the authenticated request. **Expected:** 403 and `PROFILE_VERIFICATION_REQUIRED`. **Actual:** HTTP 200. Jest failed at the expected-status assertion (line 108); therefore it did not reach the subsequent error-code assertion. This is the intended behavioral RED, not a compilation/setup/dependency failure. See `safe.log` for sanitized commands/results.

## Deviations and blockers

- The first passthrough invocation used a path relative to Jest’s `rootDir` and Jest found no tests; rerunning with `test/e2e/profile-identity.e2e-spec.ts` selected the new suite.
- The first correctly targeted run reached app construction but failed because the existing test Stripe placeholder did not satisfy `StripeProvider`’s test-key prefix check. Mirroring the existing `story-audience.e2e-spec.ts` test-only sentinel adjustment allowed the test to run. No key/credential was logged or used for a Stripe request.
- No implementation/GREEN phase started. Only the new E2E test and requested evidence files are owned by this lane. No migrations, device, non-test database, or broad gates were run.
