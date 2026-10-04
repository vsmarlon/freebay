# Backend gate record

Working revision: `c9808b106c3d53f07837542e93f25fd52c6bfbe5` plus dirty work. Commands ran serially except where noted; no credentials or raw logs are included.

| Gate | Command | Outcome |
|---|---|---|
| Focused RED | `npm run test:e2e -- --runTestsByPath test/e2e/profile-identity.e2e-spec.ts` (pre-code) | Expected fail: 1 test; got HTTP 200, expected 403 `PROFILE_VERIFICATION_REQUIRED`. |
| Typecheck | `npx tsc --noEmit` | Exit 0; no diagnostics. |
| Lint | `npm run lint` | Exit 0. |
| Unit | `npm test -- --runInBand` | Exit 0; 103 suites, 649 tests passed. |
| Build | `npm run build` | Exit 0. |
| Safety | `npm run test:safety` | Exit 0; 5/5 passed. |
| Integration, default workers | `npm run test:integration` | Runner timed out at 900 seconds. Emitted fixture FK errors and Jest hook/test timeouts; invalidated by uncontrolled DB-worker contention, not considered a pass. |
| Integration, serialized | `npm run test:integration -- --runInBand` | Exit 0; 18 suites, 102 tests passed. |
| Focused GREEN | `npm run test:e2e -- --runTestsByPath test/e2e/profile-identity.e2e-spec.ts` | Exit 0; 1 suite, 2 tests passed; covered provider failure, code-attempt exhaustion, cross-user isolation, email-change mismatch, malformed DTO, concurrent consume, replay, and success. Guarded DB sync says already in sync. |
| Full E2E | `npm run test:e2e` | Exit 0; 5 suites, 33 tests passed. |
| DTO regression | `npx jest --runInBand src/modules/users/dtos/user.dto.spec.ts` | Exit 0; 8 tests passed. |

The initial focused run exposed the expected missing-proof behavior. A later test-only fixture lookup correction replaced querying by an assumed username/email with the authenticated fixture's returned owner ID; the final focused test passed. A null-DTO assertion initially revealed that `IsCpfOrCnpjConstraint` invoked the CPF utility on `null`; its validator now narrows to string before validation, and the DTO test passes.

During expansion, an absent owner challenge with a supplied code correctly returned 410 (not 403); the test oracle was corrected to the implemented expired/missing-code contract. Concurrent wrong-attempt HTTP responses were asserted as a sorted partition because their response completion order is nondeterministic; the Redis attempt counter remains atomic.

The default-worker integration attempt exceeded the shell timeout and emitted these salient diagnostics verbatim:

```text
Foreign key constraint violated on the constraint: `Dispute_orderId_fkey`
Foreign key constraint violated on the constraint: `Order_buyerId_fkey`
Exceeded timeout of 30000 ms for a hook.
Exceeded timeout of 30000 ms for a test.
```

It was rerun with `--runInBand` against the same guarded local test DB and passed all 102 integration tests. No test database fixture or external service was manually cleaned beyond existing guarded test setup; shared PostgreSQL/Redis services were not stopped.
