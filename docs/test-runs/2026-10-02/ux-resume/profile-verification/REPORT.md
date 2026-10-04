# Profile verification backend implementation

## Identity and scope

- Tested revision: `c9808b106c3d53f07837542e93f25fd52c6bfbe5` with a dirty working tree; other concurrent work remains untouched.
- Target: local guarded `freebay_test_db`, schema `public`, plus local Redis through the application's existing test configuration. No runtime/non-test database, migration, dependency, device, or provider request was used.
- This verifies control of the account's current stored email for a proposed CPF/CNPJ mutation. It does **not** verify government identity and does not set `emailVerified` or `isVerified`.
- No raw gate logs, credentials, OTP, CPF, or email values are persisted here.
- E2E fixture/reset: `assertSafeTestEnvironment()` and a runtime `current_database/current_schema` guard required `freebay_test_db/public`; existing `cleanDatabase` ran before setup and after suite. App listener bound to `127.0.0.1` on an ephemeral port. Three disposable users exercised owner, alternate-account, and delivery-failure partitions. Only `ResendService.sendProfileVerificationCode` was replaced with a typed behavior mock that captured email/code in memory; Redis and PostgreSQL were real local test services. All seven scheduled task providers were overridden to no-ops. No shared services were stopped.

## Contract implemented

- `POST /users/me/profile-verification` accepts `{ cpf, locale?: 'pt-BR' | 'en' }`; locale defaults to `pt-BR`. Success data is `{ expiresIn: 600, resendAfter: 60 }` and contains no email, code, or secret.
- `PATCH /users/me` accepts optional `profileVerificationCode` (six digits). If `cpf` is supplied, proof is required even when it equals the stored value; clients omitting an unchanged/masked CPF need no proof. `cpf: null` and `profileVerificationCode: null` are rejected rather than treated as omitted.
- Codes are delivered to the email fetched from the authenticated owner record. Redis stores only a purpose-separated HMAC binding owner, current email, normalized proposed CPF/CNPJ, purpose, and code, with 10-minute expiry. Consume compares and deletes atomically, allowing one successful use and at most five wrong attempts. Current email is read again on consume.
- Per-user request cooldown is 60 seconds and the rolling one-hour limit is 10. Failed provider delivery creates no usable challenge and invalidates a prior challenge. Redis/provider failures fail closed.
- Stable relevant error contracts: `PROFILE_VERIFICATION_REQUIRED` (403); `INVALID_PROFILE_VERIFICATION`/`PROFILE_VERIFICATION_INVALID` (400); `PROFILE_VERIFICATION_EXPIRED` (410); `PROFILE_VERIFICATION_ATTEMPTS_EXCEEDED` and `PROFILE_VERIFICATION_RATE_LIMITED` (429); `PROFILE_VERIFICATION_DELIVERY_FAILED`/`PROFILE_VERIFICATION_UNAVAILABLE` (503). The normal error envelope is unchanged.
- On database mutation failure, proof may already be consumed; the user must request another code after cooldown. No cross-store transaction was added.

## Verification

Commands were run from `nest-backend` unless noted.

| Command | Result |
|---|---|
| Initial `npm run test:e2e -- --runTestsByPath test/e2e/profile-identity.e2e-spec.ts` before implementation | Expected RED: existing CPF update returned 200 instead of expected 403 `PROFILE_VERIFICATION_REQUIRED` (1 test failed). |
| Final `npm run test:e2e -- --runTestsByPath test/e2e/profile-identity.e2e-spec.ts` | PASS, 1 suite / 2 tests. Verifies missing-proof denial, current stored email delivery, normalized CPF persistence, neither verification flag changes, wrong-user isolation, five-attempt exhaustion, request cooldown, provider failure creates no challenge, malformed DTO does not consume proof, email-change mismatch, concurrent one-time consume, and replay rejection. |
| `npx tsc --noEmit` | PASS, no diagnostics. |
| `npm run lint` | PASS, zero warnings/errors. |
| `npm test -- --runInBand` | PASS, 103 suites / 649 tests. |
| `npm run build` | PASS. |
| `npm run test:safety` | PASS, 5/5 safety tests. |
| First `npm run test:integration` | Timed out at 900 seconds while default parallel workers were running. Output included fixture FK failures and hook/test timeouts; this run is not treated as valid functional evidence. |
| `npm run test:integration -- --runInBand` | PASS, 18 suites / 102 tests. |
| `npm run test:e2e` | PASS, 5 suites / 33 tests. |
| Final focused E2E after adding the stored-recipient assertion | PASS, 1 suite / 2 tests. |
| `npx jest --runInBand src/modules/users/dtos/user.dto.spec.ts` | PASS, 8 tests including null CPF/code rejection. |

The E2E suite's Prisma sync reported the guarded target as `freebay_test_db/public`, already in sync; no migration was created or run.

## Files owned by this implementation

- `nest-backend/src/modules/users/usecases/request-profile-verification.usecase.ts` (new)
- `nest-backend/src/modules/users/usecases/update-profile.usecase.ts`
- `nest-backend/src/modules/users/usecases/index.ts`
- `nest-backend/src/modules/users/users.module.ts`
- `nest-backend/src/modules/users/users-account.controller.ts`
- `nest-backend/src/modules/users/dtos/user.dto.ts`
- `nest-backend/src/modules/users/dtos/user.dto.spec.ts`
- `nest-backend/src/modules/users/usecases/user.usecase.spec.ts`
- `nest-backend/src/modules/users/users-controllers.spec.ts`
- `nest-backend/src/modules/auth/services/resend.service.ts`
- `nest-backend/src/shared/infra/redis/redis.service.ts`
- `nest-backend/src/shared/utils/redact.util.ts`
- `nest-backend/test/e2e/profile-identity.e2e-spec.ts`

Owned pre-edit snapshots were copied to `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-20261002-owned\backend`. The initial snapshot covered the controller, DTO, users module, update use case, Redis service and E2E spec. It did **not** include every pre-existing file later edited (ResendService, redaction utility, exports, and existing specs); those had concurrent dirty work before this task, so their exact pre-edit working-tree state cannot be restored from the snapshot. No unrelated dirty files were reverted or overwritten.

## Not verified / reviewer attention

- The HTTP+real Redis/Postgres suite does not yet exercise challenge TTL expiry, the ten-requests-per-hour ceiling, request-time invalidation of a previous challenge after cooldown, or actual Redis outage behavior. These remain for reviewer/owner follow-up.
- No frontend integration was implemented or tested. API/error code names above are the backend contract for the UI handoff.
- Same-CPF requests intentionally require fresh proof whenever `cpf` is explicitly included.
- Broad existing dirty backend/frontend work remains outside this implementation's ownership.
