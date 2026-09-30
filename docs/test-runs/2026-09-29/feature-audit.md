# Feature audit and E2E evidence — 2026-09-29

**Revision tested:** `f48a5be` on `feat/production-hardening` **plus the uncommitted working tree**. The tree was already dirty at the start; `git status --short` is required to reproduce the exact local delta. No commits were created. Local detailed chronology and FFmpeg video live in `docs/tests/2026-09-29/` (ignored through `.git/info/exclude`).

**Environment:** Windows 10; Node/Nest backend; Flutter 3.44.4 / Dart 3.12.2; local Android 16/API 36 x86_64 emulator `Small_Phone`; local PostgreSQL, Redis. E2E/integration synced the guarded `freebay_test_db` (`NODE_ENV=test`); app used the separate development database at `localhost:3000` via `adb reverse tcp:3000 tcp:3000`. `/health/ready`: DB and Redis healthy. Seeded public catalog already existed; one fresh synthetic app account was created. No credentials or personal data are recorded here.

## Commands and verdicts

| Command (working directory) | Expected / actual | Exit |
|---|---|---|
| `npx tsc --noEmit` (`nest-backend`) | Zero errors / zero errors | 0 |
| `npm run lint` (`nest-backend`) | Zero warnings / zero warnings | 0 |
| `npm test -- --runInBand` (`nest-backend`) | Passing / 99 suites, 609 tests passed | 0 |
| `npm run test:integration -- --runInBand` (`nest-backend`) | Passing / 18 suites, 102 tests passed on synced test DB | 0 |
| `npm run test:runtime-db -- --runInBand` (`nest-backend`) | Runtime query readable / 1 real read-only query passed | 0 |
| `npm run test:e2e` before changes (`nest-backend`) | All pass / 3 failures: unauthorized socket typing, global presence, public restricted comment | nonzero |
| `npm run test:e2e` after changes (`nest-backend`) | All pass / 4 suites, 25 tests passed with real HTTP/socket/DB | 0 |
| `node scripts/ci-check.js` (root) | Architecture gate / pass | 0 |
| `flutter analyze` (`frontend`) | Zero findings / zero findings after final payment UI edits | 0 |
| `flutter test test/features/cart/cart_checkout_page_test.dart test/features/payments/payment_view_test.dart` (`frontend`) | Existing suite / 8 passed; temporary new error tests removed at user request | 0 |
| `flutter test` (`frontend`) | Baseline / 232 passed **before** final payment UI change; full suite not rerun afterwards | 0 (baseline) |
| `flutter test --reporter compact` (`frontend`) after final payment UI change | Started, reached 69 passing assertions, then exceeded the 360-second runner limit; **not a passing final suite** | timed out |
| `flutter build apk --debug --target-platform android-x64 --no-pub --dart-define=API_BASE_URL=http://localhost:3000` (`frontend`) | Build / pass after removing corrupt JNI generated cache fingerprints | 0 |

Red logs from the backend unit/integration suites (e.g., mocked `StripeProvider` rejection and intentional Prisma rollback) are deliberately generated failure cases, **not** evidence of a live customer payment. The real app generated a pending checkout and attempted to open PaymentSheet; no signed, matched webhook and no completed order were observed. Two Flutter payment views had passed SDK `localizedMessage` directly to users; final code maps those failures to a generic snackbar and logs only safe diagnostic codes/types. Three temporary Stripe error regression tests were removed on user request. This last change passed analyze, eight existing focused tests and the APK build, but **could not be installed on the emulator** (disk-full after the earlier device run); the full Flutter suite timed out on its post-change retry, so mobile/final-suite outcome remains blocked.

## Repeatable device procedure / reset

1. Start a known backend process with test-mode Stripe configuration, local DB and Redis; confirm `/health/ready`; run `stripe listen --forward-to http://127.0.0.1:3000/payments/webhook` using the signing secret in backend env. Do not mix accounts/modes.
2. Free sufficient emulator storage **without wiping unrelated installed apps**. Build/install the current APK, `adb reverse tcp:3000 tcp:3000`, launch `com.freebay.app` and register a fresh synthetic buyer (or log into the synthetic account created during this run; password deliberately omitted here).
3. Explore → open real listing → Add to cart → Cart → Continue → Generate checkout → PaymentSheet. Use Stripe test credentials, then verify the matched signed webhook, order status and pending wallet in the app and DB. For earlier pending checkout, wait for configured expiry/stock release or cancel the pending order through the app; do not silently reset the dev database.
4. Capture `mobile_list_elements_on_screen`, app crash check, and safe screenshots under `docs/device-runs/2026-09-29/`; video belongs only in ignored `docs/tests/2026-09-29/` per user request. Expected/actual per journey is recorded in [`mobile-audit.md`](../../device-runs/2026-09-29/mobile-audit.md).

## Remaining gaps

Do not label release-ready: shipping/address/carrier lifecycle is missing; authenticated media/chat needs multi-device proof; push, iOS, Stripe test-mode settlement, Connect payout/refund/reversal and webhook restart proof are not verified. A wallet screenshot or payment-sheet launch does not prove money moved. Updated claims are in [`FEATURE_TRUTH.md`](../../FEATURE_TRUTH.md).
