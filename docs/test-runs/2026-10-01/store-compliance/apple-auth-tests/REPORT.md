# Apple auth focused tests

- Revision: `c9808b1` plus pre-existing dirty working-tree changes; no commit created.
- Environment: local Jest/Node, no credentials, database, migrations, sync, or live Apple requests. Apple signing keys were generated in-process; JWKS was supplied through a mocked `fetch` boundary.
- Added `nest-backend/src/modules/auth/usecases/apple-auth.usecase.spec.ts`: verified-account creation and safe session projection; subject mismatch; existing-email collision/no implicit linking; existing Apple account without email and refresh-token rotation; unverified email; deleted account.
- Extended `nest-backend/src/shared/auth/apple-provider.service.spec.ts`: real RSA-signed JWT acceptance; expired, issuer, audience, nbf, nonce, forged-signature, and unsupported-algorithm rejection.
- Command: `npm test -- --runInBand src/modules/auth/usecases/apple-auth.usecase.spec.ts src/shared/auth/apple-provider.service.spec.ts` (from `nest-backend`). Exit 0; 2 suites passed, 16 tests passed.
- One intermediate run failed compilation because the test treated `UserResponse` as having an `email` property. Corrected the assertion to check its public `displayName`; no production issue.
- The earlier provider RED noted by the parent session was a missing-service compile error, not a behavior RED; it is not counted as behavioral evidence. These added tests ran green against the current implementation. They do not verify live Apple provider behavior or database persistence.
