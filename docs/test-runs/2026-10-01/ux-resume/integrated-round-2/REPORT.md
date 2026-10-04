# Integrated Flutter validation — round 2

No source/test edits or localization generation were performed by this validation. All checks used one recursive SHA-256 manifest algorithm over the explicitly scoped Flutter source/test/native/config/assets roots, including untracked files and generated localization inputs; docs, logs, environment files and generated build/cache trees were excluded. Manifests and raw test logs are adjacent to this report.

## Commands and results

From `frontend/`:

| Command | Exit | Result |
|---|---:|---|
| `flutter test test/features/profile/follow_state_test.dart --reporter expanded` | 1 | **6 passed, 1 failed.** The new account-session seed test fails at line 411: `Expected: <2>; Actual: <3>`. The other six follow tests pass. This is not a GREEN for the deferred seed race. |
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` | 1 | `Formatted 612 files (2 changed)`: `lib/features/auth/presentation/controllers/auth_controller.dart` and `test/features/auth/apple_auth_repository_test.dart`. The command was check-only; no source was formatted/written by this run. |
| `dart format --output=none --set-exit-if-changed integration_test/native_image_compositor_test.dart` | 0 | One file, unchanged. |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | 1 | 6 issues: errors for undefined `kIsWeb` and `defaultTargetPlatform` in `login_page.dart`, and missing generated localization getters `authSignInApple` / `authSignUpApple` in login/register pages; infos at `auth_repository.dart:245` (`use_null_aware_elements`) and `apple_auth_button.dart:24` (`avoid_redundant_argument_values`). |
| `flutter test --reporter expanded` | 1 | **224 passed, 22 failed to load/run.** Final output: `04:56 +224 -22: Some tests failed.` Failure list identifies loading failures, with 18 more beyond the four printed; compilation output includes the same concurrent Apple-auth imports/localization getter mismatch. |

Full logs: `focus-follow.log`, `format.log`, `analyze.log`, `flutter-test.log`.

## Findings / current classification

- `follow_state_test.dart`: the session-seed test requests `target-user` for account A, changes to B while its status resolves, then requests a different `second-target-user`. Because `followStatusProvider` is listened to and re-evaluates for auth changes, `statusCalls` is 3 at assertion line 411, not 2. The focused run was source-stable (zero fingerprint delta). This may be an incorrect expected call count/test arrangement rather than a production defect; preserve the test and have its owner reconcile the distinct second B request with the provider's auth-reactive behavior. The race's state assertion was not reached, so this run does not establish whether the seed guard works.
- The analyzer/full-suite localization errors occurred while other workspace changes were still landing. The Apple-auth keys are present in both ARBs and generated localization sources in the latest workspace inspection, but the compile output reflects a mismatched view during execution. `kIsWeb` and `defaultTargetPlatform` are separate unresolved imports in the concurrently changing `login_page.dart`; route these to its owner. No manual localization/source repair was made.
- Full suite: the available summary reports all 22 as loading failures; test log includes compiler errors above. Treat as an unstable diagnostic, not 22 independent production defects.

## Source stability and concurrent edits

Fingerprints were captured immediately before/after each command with identical recursive discovery rules. Focused follow test: **0 changed paths**. Format: one source path changed during the command window (`frontend/lib/features/auth/presentation/controllers/auth_controller.dart`; hash changed). Analyzer: four paths changed during the command window: `frontend/lib/features/auth/auth.dart`, `frontend/lib/features/auth/presentation/pages/login_page.dart`, `frontend/lib/features/auth/presentation/pages/register_page.dart`, and `frontend/lib/features/auth/presentation/widgets/apple_auth_button.dart`. Full tests: ten paths changed during the command window: those login/register files plus `frontend/lib/features/profile/presentation/pages/privacy_page.dart`, three generated localization files, `frontend/test/features/payments/payment_view_test.dart`, `frontend/test/features/profile/follow_state_test.dart`, and `frontend/test/features/profile/profile_timeline_tabs_test.dart`. These are external concurrent edits; none were overwritten or reverted. Therefore **no frozen/stable full-gate claim** is possible.

Adjacent `source-before.tsv` and per-command `source-*-after.tsv` retain path/hash manifests. Change counts are based on path/hash identity (not Git status), so untracked files are included.

## Not run

Flutter gates failed, so APK build and root `node scripts/ci-check.js` / `npm run test:ci-scripts` were not run. No APK hash/artifact is available. Native/device/performance and `make test` remain parent-owned. No codegen was needed for the existing ARB keys; no generator invocation or hand-edit was performed. No dependency, database, migration, money, or source operation was performed.
