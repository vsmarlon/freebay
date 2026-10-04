# Current Flutter verification

- **Date:** 2026-10-01
- **Branch / HEAD:** `feat/production-hardening` / `c9808b106c3d53f07837542e93f25fd52c6bfbe5`; working tree dirty and intentionally preserved.
- **Source identity at initial gates:** SHA-256 `9a7f65d95a2bcaa8aecce1f86b5ab53f95020c835652d72159b68a4aee602ef5` over 644 content-hashed files. After concurrent WIP changed the story row, pre/post rebuild source/config identity was stable at `e76e006b3b74782c80bd18e0b09da0cd90906f5fadfc23d52ca83d2bb8f9a2d4` over 644 files. This is content identity, not a status-only digest.
- **Toolchain:** Flutter 3.44.4 stable, Dart 3.12.2. See [`flutter-version.log`](flutter-version.log).
- **Environment:** Windows; credentials omitted. No device, database, or live provider action. Existing dirty source was not fixed/reverted. No dependency, schema, or database changes made here.

## Results

| Gate | Exit | Result |
|---|---:|---|
| `dart run build_runner build --delete-conflicting-outputs` | 0 | Wrote 16 outputs. Generator warned that `--delete-conflicting-outputs` is removed/ignored by this tool version. Generated changes are the 16 outputs reported by the command; no generated files were manually edited. [`codegen.log`](codegen.log) |
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` | 1 | Five files need formatting: `login_page.dart`, `chat_header.dart`, `order_detail_page.dart`, `stories_row.dart`, `order_detail_text_scaling_test.dart`. Output-only check; no deliberate formatting write was performed. [`format.log`](format.log) |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | 1 | 22 analyzer issues (infos/warnings), including `prefer_const_constructors`, `unnecessary_non_null_assertion` at `order_detail_page.dart:425`, and `override_on_non_overriding_member` in social/story tests. [`analyze.log`](analyze.log) |
| `flutter test` | 1 | 197 passed, 86 failed at termination. First observed failures are widget tests without localization delegates (`AppLocalizations.of` null in `app_dialog_test.dart` and `app_shell_test.dart`); full output is preserved. [`tests.log`](tests.log) |
| `flutter build apk --debug` | 1 | Compile blocker: duplicate local declaration `strings` at lines 63–64 in `lib/features/stories/presentation/widgets/stories_row.dart`. No fresh APK produced. [`debug-apk.log`](debug-apk.log) |
| `node scripts/ci-check.js` | 0 | Pass; command produced no output. [`root-ci.json`](root-ci.json) |
| `npm run test:ci-scripts` | 0 | 11/11 pass. [`root-ci-scripts.log`](root-ci-scripts.log) |

## APK availability

The initial build failed on the duplicate story-row declaration and did not produce a fresh APK. Existing prior artifacts at that point were stale: `app-debug.apk` was 177,384,950 bytes, modified 2026-09-30 00:47:49 -03:00, SHA-256 `072ea87d9a2786bb17f01d473d55139d07e9bbb3c80f7712077babefa191fb1c`; `app-profile.apk` was 91,488,797 bytes, modified 2026-09-30 01:45:18 -03:00, SHA-256 `82bfdc51e2b24583761d55297861709f6e813ef223b4a1b1f8fac5c0d3d2725a`.

### Concurrent WIP follow-up build

After the owner confirmed the duplicate declaration had been removed by concurrent WIP, one new `flutter build apk --debug` run passed (exit 0; 371 seconds) without source edits. See [`debug-apk-rerun.json`](debug-apk-rerun.json) and [`debug-apk-rerun.log`](debug-apk-rerun.log). The 644-file source/config content identity immediately before and after stayed `e76e006b3b74782c80bd18e0b09da0cd90906f5fadfc23d52ca83d2bb8f9a2d4`. Fresh APK: `frontend/build/app/outputs/flutter-apk/app-debug.apk`, 249,976,406 bytes, modified `2026-10-01T03:49:44.3862558-03:00`, SHA-256 `94edf1a02df7aebc5477fa764259ee1fc81f922b65e1afeeb82ab653c040c025`.

`frontend/lib/shared/config/app_config.dart` resolves the public development API URL to `http://localhost:3000`, matching the expected device reverse mapping `3000 → safehost:3110`. Device mapping/install was not inspected or performed in this lane.

## Readiness

**Current debug APK is ready for the parent-owned device install against the stated source identity. Full Flutter gates are not green.** Analyzer and format gates independently fail, and the test suite has broad localization-harness failures. Root checks pass. This lane made no source/test/codegen/format fix or device action after the successful rebuild. Device UX, native compositor execution, payment/provider settlement, production DB/runtime, and performance remain outside this evidence.
