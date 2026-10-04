# Store compliance backend slice — partial

**Revision:** `c9808b1` with the integrated dirty working tree preserved. No commits made.  
**Scope implemented here:** Apple auth backend and pre-deletion Apple credential revocation only.  
**Database:** no database queried or changed. Prisma client generation only; production/runtime/test schemas are not verified.

## Changes owned by this slice

- `nest-backend/prisma/schema.prisma`: approved nullable `appleId @unique` and `appleRefreshTokenEncrypted` fields. The file also had pre-existing dirty BlurHash edits; those were preserved.
- Apple auth: `src/shared/auth/apple-provider.service.ts`, `src/modules/auth/usecases/apple-auth.usecase.ts`, DTO/controller/module/repository wiring, and Apple errors.
- Account deletion: attempts Apple revocation after existing financial blockers; leaves sessions and account state alone on missing credential/provider failure; clears Apple fields during final purge.
- Tests: provider encryption-key/ciphertext coverage, deletion revocation-failure coverage, and controller test DI update.

## API and configuration

`POST /auth/apple` accepts `{ identityToken, authorizationCode, rawNonce, fullName? }` and returns the existing `AuthSessionResponse` envelope. Invalid credentials map to `INVALID_APPLE_TOKEN` (401); account email collision maps to `APPLE_EMAIL_COLLISION` (409); missing Apple config maps to `APPLE_UNAVAILABLE` (503). Deletion cannot proceed without a stored revocable token or when Apple revocation fails (`APPLE_REVOCATION_REQUIRED`, 409). Apple configuration names are `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, and `APPLE_TOKEN_ENCRYPTION_KEY` (32-byte base64 AES-256 key). No example secrets or invented IDs were added.

The flow verifies RS256 Apple JWT signature/issuer/audience/expiry/nonce, exchanges the single-use authorization code, checks returned subject and nonce, requires a verified email for new accounts, refuses email-based linking, and encrypts the returned refresh token using AES-256-GCM. This has not been exercised against Apple.

## Verification

- `npm test -- --runInBand src/shared/auth/apple-provider.service.spec.ts` — initial run failed during compilation because the new service did not exist yet; this was scaffolding failure, **not** a valid behavioral RED. After implementation, provider tests passed (2/2).
- `npm test -- --runInBand src/modules/users/usecases/request-account-deletion.usecase.spec.ts src/shared/auth/apple-provider.service.spec.ts` — passed (17/17).
- `npm test -- --runInBand src/modules/auth/auth.controller.spec.ts src/modules/users/usecases/request-account-deletion.usecase.spec.ts src/shared/auth/apple-provider.service.spec.ts` — passed (30/30).
- `npx prisma generate` — passed (Prisma Client v7.4.2); no DB operation.
- `npx tsc --noEmit` — passed after Prisma generation.
- `npm run lint` — passed (zero warnings).
- `npm test -- --runInBand` — passed (100 suites, 618 tests).
- `npm run build` — passed.
- `npm run test:safety` — passed (5/5).
- Integration/E2E/database synchronization commands were not run: the approved stop rule forbids any DB sync/push/seed here. No migration was created or executed.

## Explicitly incomplete / release blockers

This is **not** completion of the approved store-compliance slice. Not implemented or proven: fresh-auth enforcement for deletion cancellation; safe public account-deletion resource flow for provider-only accounts; correction of stale/inaccurate copy in the existing `legal/delete-account.html`; allowlisted per-model export projections (existing export still uses broad model reads); export scope/retention disclosure; privacy legal source changes; Apple auth use-case behavioral tests for JWT failures, replay/subject mismatch, email collision, and returned-token errors; startup/production configuration validation; runtime DB schema deployment; Apple provider proof. No truthful claim can be made that the public deletion resource supports Apple-only/Google-only accounts or that cancellation meets the fresh-auth contract.

The first full backend test run exposed missing test DI for the newly added controller dependency; the owned controller spec was updated. The final full suite passed. Existing working-tree changes outside the owned slice were left untouched.
