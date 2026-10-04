# Store compliance frontend regression verification

**Revision:** `c9808b106c3d53f07837542e93f25fd52c6bfbe5` plus a heavily dirty shared working tree. No credentials, database, provider, or device were used. Fixtures are in-memory Riverpod/repository doubles; tests do not establish Apple provider delivery or live payment settlement.

## Owned change

- `frontend/test/features/payments/checkout_order_amount_test.dart` — performs the page checkout with listing price 10,000 cents and created order amount 12,500 cents, then asserts the native wallet receives 12,500. This catches substituting the product display price for the authoritative created-order amount.

No production or backend files were changed. An Apple controller-level test was not added: existing nonce-helper and repository HTTP tests pass, but the remaining controller-to-native-SDK nonce/credential handoff and cancellation/session branches are not covered here. No provider/device proof is claimed. Existing dedicated Apple tests were preserved and run.

## Commands and results

- `dart format test/features/payments/checkout_order_amount_test.dart` — passed; formatted the owned test.
- `flutter test test/features/payments/checkout_order_amount_test.dart` — **1 passed, 0 failed**.
- `flutter test test/features/auth/apple_auth_nonce_test.dart test/features/auth/apple_auth_repository_test.dart test/features/payments/payment_page_test.dart test/features/payments/payment_view_test.dart test/features/cart/cart_checkout_page_test.dart` — **12 passed, 2 failed**. Existing payment-page text-scale tests failed; details below.
- `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` — **failed (exit 1)**, reported `Changed test\features\payments\payment_page_test.dart`; no file was written by `--output=none`. That file was concurrently changed by the UX workflow; it was not formatted or otherwise modified by this test work.
- `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` — **failed (exit 1), 4 issues at run time**: `test/features/payments/checkout_order_amount_test.dart:23:8` unnecessary import (removed afterward); `test/features/profile/edit_profile_page_test.dart:6:8` unused import and `:61:16` missing `const`; `test/features/profile/profile_settings_sheet_test.dart:106:5` `avoid_print`. The latter profile files are outside this work and were not changed here. Analyzer was not rerun after removing the owned import.
- `flutter test` — **failed (exit 1): 290 passed, 4 failed**. Two payment-page text-scale failures and two concurrent profile test failures listed verbatim below. This supersedes no claim about the prior root timeout baseline; it is the observed shared-tree run.
- `flutter build apk --debug` — passed (exit 0), produced `frontend/build/app/outputs/flutter-apk/app-debug.apk`; build emitted existing Kotlin plugin compatibility and untranslated localization warnings.

### Focused post-run verification

After removing the owned test's unnecessary import, `dart format --output=none --set-exit-if-changed test/features/payments/checkout_order_amount_test.dart` exited 0 (`Formatted 1 file (0 changed)`) and `flutter analyze --fatal-infos test/features/payments/checkout_order_amount_test.dart` exited 0 (`No issues found`, 11.3s). Root `git diff --check` exited 0 with CRLF normalization warnings only. This is scoped verification of the owned test, not a rerun of the full analyzer or format gate: the earlier full analyzer result (including the then-present owned import and three unrelated profile issues) and full-suite failures remain as recorded above. The frontend reviewer marked the scoped test change **SHIP**; this does not change the reported suite/gate failures or cover the Apple controller-to-SDK boundary.

### Failures

Focused run and full suite both observed:

```text
Expected: null
  Actual: FlutterError:<A RenderFlex overflowed by 98 pixels on the right.>
The test description was:
  loaded checkout fits at 1.5x with long details
```

```text
Expected: null
  Actual: FlutterError:<A RenderFlex overflowed by 361 pixels on the right.>
The test description was:
  loaded checkout fits at 2.0x with long details
```

Full-suite-only additional failures:

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Ada Example": []>
The test description was:
  prefills own profile fields when the HTTP profile arrives after mount
```

```text
The finder "Found 0 widgets with text "PROFILE HEADER": []" (used in a call to "getCenter()") could
not find any matching widgets.
The test description was:
  profile tabs page independently without changing shell branch
```

The profile failures are in concurrently changed UX/profile tests and are reported, not attributed to this work. No unrelated production fixes were attempted. Full Flutter test output was retained by the command runner; the full run completed and is not an interrupted result.
