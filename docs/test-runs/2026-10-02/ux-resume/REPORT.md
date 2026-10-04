# UX resume validation — 2026-10-02

**Status: not integrated GREEN.** This checkout and Galaxy A30 remain shared with concurrent agents. No reset, revert, commit, migration, schema synchronization, fixture reprovision, or payment/provider operation was performed by this validation session. Other agents' source and evidence are preserved.

## Provenance and environment

- Branch/revision: `feat/production-hardening` at `c9808b106c3d53f07837542e93f25fd52c6bfbe5` plus dirty changes. At 14:28:25 UTC, Git reported 424 status paths and 2 stashes. This is not a frozen source revision.
- Windows; Flutter CLI 3.44.4 / Dart 3.12.2 (`C:\Users\Qiyana\fvm\default`). An independently running app used Flutter 3.35.6; it was not stopped or attributed to this build.
- Each gate directory contains its exact command/log, exit result, UTC window, Git status, and before/after recursive SHA-256 manifests. Scope is Flutter sources/tests/assets/native files and selected Flutter build configs, plus root scripts/perf and backend source/tests/Prisma/config files. Environment files, private sessions, docs/logs, caches and build outputs are excluded. A changed hash contributes two manifest rows, an addition/removal one. Zero delta establishes only scoped source identity during that command, not production readiness or a frozen sequence of gates.
- Device: physical Samsung Galaxy A30 SM-A305GT, Android 11, `RX8M70JDTQV`. Initial observation was FreeBay login, not the prior messages screen. Existing reverse mapping was `tcp:3000 → tcp:3000`; it was inspected, not changed by this session.

## Current verification

Commands run in `frontend/` unless the row says root. Raw evidence is adjacent in the named directories.

| Evidence directory | Command | Exit / observation |
|---|---|---|
| `follow-current` | `flutter test test/features/profile/follow_state_test.dart --reporter expanded` | 0; **7/7 passed**, including pending-mutation and deferred-status account isolation. Scoped source delta 0. The test arrangement had already been reconciled by concurrent work; no follow edit here. |
| `format`, `format-after`, `format-final-source` | `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib integration_test/native_image_compositor_test.dart` | 1 each; moving test-only format findings. Check-only. A small settings-test whitespace correction was made here; subsequent semantic/import repairs came from its other owner. |
| `analyze-current` | `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | Harness timeout at 180 seconds before analysis output; blocked, not passed. |
| `analyze-retry`, `analyze-after`, `analyze-final-source` | Same analyzer command | 1 each: first five settings-test setup errors, then two unused imports, then seven concurrent payment-test setup errors. Do not attribute those snapshots to one stable state. |
| `full-tests` | `flutter test --reporter expanded` | 1; **287 passed / 4 failed**. Two checkout scaling overflows (98/361 pixels), settings drag top unchanged (60), and missing profile-header finder. Three paths changed during the window: two profile tests and a backend Apple-auth spec. No integrated GREEN. |
| `focused-current-failures` | `flutter test test/features/payments/payment_page_test.dart test/features/profile/profile_settings_sheet_test.dart test/features/profile/profile_timeline_tabs_test.dart --reporter expanded` | 1; 1 passed / the same 4 failed. Scoped delta 0. Profile and payment files remain with their concurrent owners; assertions were not weakened here. |
| `root-ci-check` | Root: `node scripts/ci-check.js` | 0; scoped delta 0. |
| `root-ci-scripts` | Root: `npm run test:ci-scripts` | 0; **14/14 passed**, scoped delta 0. |
| `make-test-last` | Root: `make test` | 2; backend lint and Flutter analyzer passed, then the check-only format gate failed on `test/features/payments/payment_page_test.dart` (618 files checked, 1 finding). Later root checks/unit/integration steps were not reached. Window: 14:52:59–15:00:09 UTC; 10 changed manifest rows, so not a stable integrated result. |
| `format-after-make` | `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib integration_test/native_image_compositor_test.dart` | 1; the payment-page test remains the only finding (619 files checked). Scoped delta 0. Its concurrent owner's file was not changed here. |
| `sheets-after-make` | `flutter test --no-pub test/design_system/brutalist_bottom_sheet_test.dart test/features/profile/profile_settings_sheet_test.dart --reporter expanded` | 0; **3/3 passed**, scoped delta 0. Independently confirms the other owner's shared-sheet repair, including overflowing-body dismissal, partial/reverse drag, settings scroll/tap and shell-route isolation. Widget evidence only. |

## Backend/fixture boundary

The inherited `:3110` process was stopped. Read-only `.env.test` checks validated local `freebay_test_db/public`, recovery false. One readiness attempt timed out and a later one passed. After the guard passed, the audited private bootstrap was restarted on loopback `127.0.0.1:3110`, PID 43592, with fake/test Stripe configuration, Firebase absent, and cleanup task providers disabled. This uses existing compiled backend artifacts, not a new source/build verification.

`backend-preflight/` records exit 1: private fixture login returned **HTTP 401 / INVALID_CREDENTIALS**. `fixture-readback/` records a guarded read-only check, exit 0: the private fixture user no longer exists and its post/product/story counts are zero. No password or fixture repair was attempted. The reused private preflight helper now accepts `UX_PREFLIGHT_REPORT` so a new run does not overwrite yesterday's report. Credentials/tokens remain only in private temporary storage.

Authenticated U8 smoke and feed performance require a valid, representative fixture. An empty/unauthenticated run is not measured evidence; the null feed baseline is not a performance pass. Unsafe reprovision scripts were not run.

The requested post-`make test` preflight is recorded in [`backend-preflight-after-make/REPORT.md`](backend-preflight-after-make/REPORT.md): exit 1, scoped delta 0, `Unexpected end of JSON input` before ownership validation. Independent PID readback confirmed saved PID 43592 was absent. No database, login or fixture check ran; the historical report was not overwritten, and no backend/fixture repair was attempted.

## Native editor investigation

`native-compositor/` records the unmocked A30 command `flutter test integration_test/native_image_compositor_test.dart -d RX8M70JDTQV --reporter expanded`, exit 1, 0 passed / 2 failed. Build/install succeeded, but the editor failed layout before export: `_Tab` returned `Expanded` inside the horizontal toolbar scroller's unbounded `Row`. The leftover broken widget tree also contaminated the pixel case; this is **not** evidence of a rotation pixel mismatch. Concurrent changes during this command were outside the native/editor source and test.

All toolbar callers were traced: the single `ImageEditorPage` owner is reached by chat, post and story editor routes. The minimal shared fix replaces `_Tab`'s `Expanded` with a naturally sized `ConstrainedBox` using Flutter's minimum interactive width. Existing labels, callbacks, export/channel contracts and every pixel assertion are preserved. The existing real-device integration test is the regression check; no new test-only seam or compositor algorithm edit was added. Post-fix native and scoped gates are recorded separately when complete.

- `toolbar-analyze/`: the scoped toolbar + native-test analyzer exited 0, no issues; unrelated concurrent paths changed, not either analyzed file.
- `toolbar-format-write/` formatted the owned toolbar only. `toolbar-format-resumed/` then exited 0, 2 files unchanged, scoped delta 0.
- `native-compositor-after-toolbar/`: **cancelled by the OpenCode server restart**, no test verdict/exit code. The saved output reaches build/install and the first test only; a recovery fingerprint is explicitly not an exact cancellation boundary.
- `native-compositor-resumed/`: **blocked by the 420000 ms harness timeout during Gradle `assembleDebug`**, before build/install or tests. The retry used `--no-pub --no-uninstall --timeout 120s`; that test timeout did not establish an assembly deadline or a test verdict. Its after-timeout fingerprint is a recovery snapshot, not an exact timeout boundary. Neither post-fix run proves native pixel correctness.
- After restart, CLI/ADB remain available. The observed device was at the Android launcher; no auth/navigation state is assumed. Another agent's Flutter tests were left running.

The repeat private preflight (`backend-preflight-after-native/`) failed before its guard completed with `Unexpected end of JSON input`; the owned bootstrap process was no longer present after the restart. This is blocked environment evidence, not an auth or fixture pass. It did not overwrite historical preflight output.

Before the native command overwrote the build output, the existing APK was copied to private `freebay-ux-resume/app-debug-prior-unverified.apk`, SHA-256 `B8FC267C386E969A5189BA7DEE9C2C82D56987B7A5C62A7A1A4695C41F2B10D1`. It is deliberately **not** labeled a fresh normal-app APK. A normal `lib/main.dart` APK remains gated by the failed Flutter verification; no `app-debug-main.apk` claim yet.

Crash inspection before native retry found only a historical Samsung Forest crash (2026-10-01), no FreeBay crash record. Flutter layout exceptions are still failures even without an Android process crash.

[`gradle-status-diagnostic/REPORT.md`](gradle-status-diagnostic/REPORT.md) records read-only daemon/process/thread inspection after the timeout. Another session's normal `lib/main.dart` APK build occupied the shared Android build directory; its daemon was BUSY and in task execution/Kotlin compilation. No competing native build was started, no process was stopped, and no cache/configuration was changed. This current snapshot does not prove the earlier native timeout's cause or either build's success.

## Remaining limits

- Normal-app APK, post-fix native verdict, authenticated bounded U8 smoke and valid feed baseline/comparison remain blocked. The latest `make test` stopping point is recorded above; it is not a full-gate pass.
- iOS native parity, comparable pre-change U5 timing, production/staging schema, settled payments/webhooks/payouts and push delivery remain blocked/out of scope. No inference from mocks, test DB, APK or source review.
- Other sessions' `preflight/` and `flutter-prep/` reports are separate ownership/evidence, not results from this validation session.

## Next gates and ownership

1. Payment-test owner: resolve its format finding and the previously reproduced 1.5×/2× checkout overflows. Profile-timeline owner: reconcile the retained header/scroll failure without removing its observable assertions. Neither file nor its production owner was changed here.
2. After those repairs, rerun Flutter format/analyze/full tests with source fingerprints; the sheet subset above does not make the earlier full suite green. Root script checks and the follow subset already passed and were not needlessly repeated.
3. In a non-competing Android build window, establish the post-toolbar native verdict with every existing exact RGBA rotation/inverse assertion intact; preserve normal-app and native-test APK provenance separately.
4. Once Flutter gates actually pass, build/hash/copy the normal `lib/main.dart` APK to private `freebay-ux-resume/app-debug-main.apk`. Do not relabel the prior backup or another session's in-progress build as this artifact.
5. Backend/fixture owner must restore a verified guarded backend and representative authorized fixture before authenticated U8 smoke or feed baseline/comparison. Unsafe fixture reprovision remains withheld.

Evidence-document checks: scoped `git diff --check` exited 0 (only Git's LF/CRLF advisory); local Markdown destination validation checked 16 links across the four edited/added evidence documents, exit 0, no missing destinations (`evidence-consistency/result.json`). New diagnostic logs contained no credential/header/connection-string matches in the targeted redaction scan. These are documentation checks, not release gates.
