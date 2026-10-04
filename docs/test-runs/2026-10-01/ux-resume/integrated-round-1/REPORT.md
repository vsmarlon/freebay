# Integrated Flutter validation — round 1

**Scope:** Flutter format, analyzer, and complete test suite after integrated UX work. No source or test files were changed in this validation. Device/native integration, root `make`, and APK build were not run because the full Flutter test gate failed.

## Commands and results

Run from `frontend/` unless noted:

| Command | Exit | Result |
|---|---:|---|
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` | 0 | Formatted 605 files (0 changed). |
| `dart format --output=none --set-exit-if-changed integration_test/native_image_compositor_test.dart` | 0 | Formatted 1 file (0 changed). |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | 0 | No issues found. |
| `flutter test --reporter expanded` | 1 | 277 passed, 6 failed. Final output: `00:46 +277 -6: Some tests failed.` |
| `flutter test test/features/auth/login_text_scaling_test.dart test/features/profile/follow_state_test.dart test/features/product/product_load_more_error_test.dart test/features/social/feed_append_retry_test.dart --reporter expanded` | 1 | Focused rerun confirms 6 failures in login text scaling, follow state (4 cases), and feed append retry. Product load-more suite passes focused. |

Logs: `format.log`, `analyze.log`, `flutter-test.log`, and `focused-failures.log` in this directory.

## Failures for executor

- `test/features/auth/login_text_scaling_test.dart`, `login form remains scrollable and readable at 2.0x`: expected no Flutter exception; actual `FlutterError:<A RenderFlex overflowed by 10.0 pixels on the right.>` at test line 56. 1.5x cases pass. This is a real accessibility/layout regression signal, not a harness/setup failure.
- `test/features/profile/follow_state_test.dart`: optimistic update/confirmation; rollback on failure; duplicate pending tap; and following-feed reset after success all fail. The duplicate-tap case expected one repository call, actual zero. Focused output confirms failures; inspect test fixture/provider wiring alongside the provider behavior before deciding whether production code or harness is wrong. No production fix was attempted.
- `test/features/social/feed_append_retry_test.dart`, `failed append keeps posts and offers a deliberate retry`: expected exactly one `TENTAR NOVAMENTE`, actual zero; test line 55. The `pt_BR` copy may be a brittle locale expectation, but behavior needs checking against current localized retry action. No assertion was weakened.

The focused command's exact failure summary is retained in `focused-failures.log`; full command output and final suite summary are in `flutter-test.log`.

## Stability caveat

The pre-run SHA-256 manifest was captured with an incomplete file-discovery approach, while the after-run manifest used recursive discovery; their counts differ (367 vs 2889), so this is **not a valid before/after source-stability comparison**. No source edits were made by this validation, but concurrent/untracked source changes cannot be ruled out from these manifests. The report/log files are evidence outputs and excluded from source consideration. Do not treat the test results as a frozen, reproducible green baseline.

## Blocked / not run

APK build, native integration/device validation, and root `make test` were not run: the full test gate failed and parent owns device execution. No package install, code generation, database action, or production change was made.
