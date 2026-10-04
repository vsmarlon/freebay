# Store-compliance verification — 2026-10-02

**Revision:** `c9808b1` plus dirty working-tree changes in a shared workspace; no commit or staging performed. This report covers only the store-compliance changes and evidence listed here.

## Verified

- Backend Apple-auth deletion-race fix and focused/full verification: [backend report](backend/REPORT.md). Final backend suite: 103 suites / 648 tests; focused: 5 suites / 41 tests. TypeScript, lint, build and safety gates passed.
- Root `node scripts/ci-check.js` and `npm run test:ci-scripts` (14/14) passed, as reported by the parent session. No other root or database gate is claimed here.
- The backend final reviewer marked the change **SHIP**; incremental security review **PASS** with the low residual post-update-to-session race noted below. These reviews cover the narrow Apple-auth change, not account deletion/purge certification.
- Frontend results: [frontend report](frontend/REPORT.md). The new checkout amount regression passed 1/1; existing Apple nonce-helper/repository tests passed. Full Flutter suite: 290 passed / 4 failed; debug APK build passed. Full format and analyze gates failed as detailed in that report.
- Focused post-run checks for the owned checkout test passed: formatter check (1 file, 0 changed) and `flutter analyze --fatal-infos` on that test reported no issues. Root `git diff --check` passed (CRLF normalization warnings only). Frontend reviewer marked the scoped test change **SHIP**; this does not make the full format/analyze gates green. Backend reviewer also marked its scoped change SHIP; final incremental security review PASS applies only to that delta.
- Current source includes the Apple native-login client flow and backend integration; this is a code-path statement, not provider, device, or release-build proof.
- In single-order checkout, `PaymentPage` passes the created order's `amount` to `PaymentView` and the wallet controller. The new test checks that the wallet receives 12,500 cents when the listing price is 10,000 cents. It does not establish native UI display, a successful payment, webhook settlement, or device behavior. Native cart checkout uses the backend group amount; earlier PaymentSheet device evidence describes the then-present UI, not the current single-order wallet path.

## Pending / limits

- Frontend verification is not all green. The focused new checkout regression passed 1/1; existing Apple nonce-helper/repository tests passed, but no controller-to-native-SDK nonce/credential handoff or cancellation/session-branch test was added. Full Flutter suite had 290 passed / 4 failed (two payment-page text-scale overflows and two profile failures in the concurrent UX tree); full format and analyze failed. The debug APK build passed. Exact output and attribution limits are in the [frontend report](frontend/REPORT.md); no failures were fixed or attributed to this work.
- No Apple provider/JWKS network call, native device/browser journey, production origin, email/relay delivery, live database/schema, migration, release signing, Apple Pay/Google Pay production transaction, or store submission was tested.
- Conditional Apple credential rotation prevents issuing a session after a deleted-row no-match, but does not make the later session-issuance step atomic with concurrent deletion. The incremental security review rated this residual race low; it remains a limit, not a release certification.
- Account purge remains incomplete and potentially destructive. Personal-content deletion is approved but implementation is blocked and not landed; the existing scheduled task and repository were not changed or disabled. Existing gaps include Apple-token revocation, authored-content anonymization/deletion, retry-safe external media deletion, and reliable shared-media ownership/concurrency. Orders, transactions, wallet, and disputes are approved for preservation; only legal review/justification of retention periods remains pending. No additional media schema, outbox, ownership system, or coordination mechanism was authorized or introduced.
- The approved persistence/dependency snapshot remains only `User.appleId` and `User.appleRefreshTokenEncrypted`, `sign_in_with_apple` 8.2.0 and direct `crypto` 3.0.7; no DB, migration, sync, or seed operation occurred.
- Controller/contact details, legal approval, Apple environment secrets, native Apple Pay merchant setup, Google Pay production setup and trusted production origins remain owner/release gates.

## Scope and evidence boundaries

Only documentation was changed by this reporting session. The production fix and backend test evidence are documented in [backend/REPORT.md](backend/REPORT.md). Existing historical reports were left unchanged. No database operation, migration, sync, seed, provider/device test, or commit was performed for this documentation update. Do not treat this report or the checklist as a declaration that submission requirements are complete.
