# 2026-09-28 — response cleanup and chat reply redaction

**Tested revision:** `f48a5be008ea8520995e68441656899499ca08a1` plus the uncommitted working tree on branch `feat/production-hardening` (including pre-existing frontend/social/schema edits). Reproduce that tree with `git status --short` and `git diff`; this is not a claim about the base commit alone. No files were committed or pushed.

**Environment:** local Windows, Node v24.10.0, Flutter 3.44.4 / Dart 3.12.2. The guarded `.env.test` integration/E2E target was PostgreSQL `freebay_test_db`, schema `public`, localhost:5432; credentials omitted. The separate `.env` runtime-database smoke test connected read-only through `PrismaService`; it exercised the transfer-failure query only, not every column or release schema. No physical device, live Stripe payout or media provider was used.

**Device availability:** `mobile_list_available_devices` returned `[]`; the Android/iOS checkout, chat, save, fulfillment and payout device matrix could not run locally. No cloud device was requested or allocated.

**Fixtures/reset:** `npm run test:integration` synchronizes only the guarded test database and truncates test tables after each integration case (`nest-backend/test/setup-integration.ts`). `npm run test:e2e` also synchronizes the guarded test database; the marketplace journey truncates its fixtures at startup and removes uploaded files at shutdown, while story highlights clean at setup/teardown. Re-run against `freebay_test_db` only; E2E marketplace rows may remain until its next setup.

| Step (cwd) | Expected | Observed | Exit |
|---|---|---|---|
| `npx jest src/modules/chat/usecases/get-starred-messages.usecase.spec.ts --runInBand --silent` (`nest-backend`, before fix) | hidden text and attachment after view-once/deletion | 2 intended failures: returned `segredo` and `/media/chat/reply.jpg` | nonzero (RED) |
| same command after fix | redaction passes | 6/6 tests passed | 0 |
| `npm run tsc:check`, `npm run lint`, `npm run build` (`nest-backend`) | no type/lint/build errors | passed | 0 |
| `npm test -- --runInBand --silent` (`nest-backend`) | suite passes | 99 suites, 609 tests passed | 0 |
| `npm run test:integration -- --runInBand --silent` (`nest-backend`) | real test-DB checks pass | schema already in sync; 18 suites, 102 tests passed | 0 |
| `npm run test:e2e -- --silent` (`nest-backend`) | HTTP journeys pass | 2 suites, 19 tests passed; Stripe provider substituted in marketplace journey | 0 |
| `npm run test:runtime-db` (`nest-backend`) | configured runtime DB read-only reconciliation query succeeds | 1 smoke test passed | 0 |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` (`frontend`) | zero issues | zero issues after removing three redundant test fixture arguments | 0 |
| `flutter test --reporter compact` (`frontend`) | unit/widget suite passes | 229 tests passed; initially 1 pending Riverpod timer in a pre-existing regression test, fixed by disposing its test container before the fake-async test ended | 0 on rerun |
| `dart format --output=none --set-exit-if-changed frontend/lib frontend/test frontend/libs/freebay_design_system/lib` (root) | format gate passes | initially 20 files in the pre-existing dirty tree needed formatting; formatted those files and reran: 0 changes | 0 on rerun |
| `node scripts/ci-check.js` (root) | architecture gate passes | passed | 0 |
| `flutter build apk --debug` (`frontend`, default cache) | Android debug APK builds | Gradle `:jni:configureCMakeDebug[arm64-v8a]` failed: cached `configure_fingerprint.bin` in external pub cache returned `unrecognized RECORD_NOT_SET` (`CXX1420`) | 1 |
| `$env:PUB_CACHE='C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-pub-cache'; flutter pub get && flutter build apk --debug` (`frontend`) | isolate corrupt cache and build arm64 debug APK | built `build/app/outputs/flutter-apk/app-debug.apk`; dependencies unchanged, no existing pub-cache files removed; afterward ran `flutter pub get` with the normal cache to restore project dependency resolution | 0 |

**Limits:** No chat-socket E2E or real user session tested view-once behavior; the RED/GREEN regression exercises the use case with a substituted repository. Runtime schema smoke does not prove schema-wide drift absence. The Android build succeeds with an isolated cache, while the ordinary cached build remains reproducibly broken until its external JNI cache is repaired; no existing external cache was modified. `docs/FEATURE_TRUTH.md` tracks the remaining frontend, backend, database, device and provider gaps. No screenshot or device log exists for this run.
