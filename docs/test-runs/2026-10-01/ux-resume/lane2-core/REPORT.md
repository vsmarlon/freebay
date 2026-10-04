# UX resume — Lane 2 core tests

## Identity and scope

- Repository: `C:\Users\Qiyana\Documents\GitHub\ME\freebay`
- HEAD: `c9808b106c3d53f07837542e93f25fd52c6bfbe5`
- Working tree: deliberately dirty and shared. Parent pre-edit snapshot: `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-20261001-start` (`start.patch`). Do not attribute unrelated changes to this lane.
- Baseline supplied by parent: `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-tests-baseline.log`, SHA-256 `681338D543A68F94937856A771927AE8CE36E5A0046F2477095A5317D1BBD397`; exit 1, 208 passed / 75 failed. This is the current baseline, not the historical 197/86 result.
- Owned test surface: `app_dialog_test.dart`, `app_shell_test.dart`, `app_video_viewer_test.dart`, `empty_state_test.dart`, `shimmer_scope_test.dart`, and `app_router_test.dart`.
- No production files changed. No device, DB, credentials, dependencies, schema, API, money/provider behavior, commits, or broad gates used.

## Test-audit contract and failure classification

| Test | Observable contract / credible regression | Why broader coverage does not replace it / seam | Baseline classification and action |
|---|---|---|---|
| `app_dialog_test.dart` | Non-dismissible dialog rejects back navigation. | Direct widget interaction covers its UI contract; no production behavior change. | Baseline passed 1/1; untouched. |
| `app_shell_test.dart` | Five-way tab order, inner-vs-shell gestures, drawer edge gesture, scrolling chrome and keyboard layout. | Direct shell gestures/layout are not established by unit or backend coverage; no test seam. | Retained unchanged. |
| `app_video_viewer_test.dart` | Preview remains paused/opens fullscreen; controls update position, playback, mute, retry and semantics. | The platform fake drives observable player events; no broader test covers this exact control journey. | Stale expected replay semantics label: localized production value is `Reproduzir vídeo novamente`, distinct from play label `Reproduzir vídeo`. Updated only that expectation; gesture/action assertions retained. |
| `empty_state_test.dart` | Retry action invokes callback. | Direct visible UI action; no stronger boundary covers it. | Fixture omitted generated localization delegates; added SDK-generated delegates/supported locales with explicit `pt_BR`. No behavior change. |
| `shimmer_scope_test.dart` | One shared ticker, reduced-motion stop, theme roles and enabled/disabled accessible icon semantics. | Timing and accessibility semantics are design-system/widget contracts, not covered by app E2E. | Original failure was matcher/API representation mismatch (`Tristate`). SDK inspection confirmed `SemanticsFlags.isEnabled` is `dart:ui`'s `Tristate`; import it explicitly and compare `Tristate.isTrue` / `Tristate.isFalse` directly. All interaction/action/size assertions retained. |
| `app_router_test.dart` | Typed route encoding, redirect destinations, complete-profile dialog, logout and login navigation. | Router-level state transitions are distinct from leaf UI/backend checks. | Fixture omitted localization delegates; added generated delegates/supported locales with explicit `pt_BR`. Replaced a tooltip finder with the production button's actual semantic-label finder; label assertion retained. This fixes stale test API usage, not production. |

Failure classification came from the supplied current baseline plus source tracing: EmptyState and CompleteProfilePage require `l10n(context)`; generated catalogs define video play/replay labels separately; `AuthHeader` exposes its back label as a semantic label, not a tooltip. No production defect was established, so none was proposed or changed. No test was removed, skipped, weakened, or made conditional.

## Verification

All commands ran from `frontend`.

- `dart format --output=none --set-exit-if-changed test/core/components/app_dialog_test.dart test/core/components/app_shell_test.dart test/core/components/app_video_viewer_test.dart test/core/components/empty_state_test.dart test/core/components/shimmer_scope_test.dart test/core/router/app_router_test.dart` — exit 0; `Formatted 6 files (0 changed)`.
- `flutter analyze --fatal-infos test/core/components/app_dialog_test.dart test/core/components/app_shell_test.dart test/core/components/app_video_viewer_test.dart test/core/components/empty_state_test.dart test/core/components/shimmer_scope_test.dart test/core/router/app_router_test.dart` — exit 0; `No issues found!`.
- A single combined `flutter test` invocation exceeded the 300-second command limit under concurrent/shared-tree load. Retried one test file per process (same six owned paths, exact commands/results in `focused.log`); all passed, 1 + 8 + 3 + 1 + 6 + 7 = 26 tests. Sequential focused run exit 0.
- Full Flutter suite/analyze/format, build, device, and backend gates were not run (per lane constraints); no claim is made for them.

### Review correction — typed shimmer state

The installed SDK API was inspected with Dart MCP: `package:flutter/semantics.dart` exports Flutter semantics, while `package:flutter/src/semantics/semantics.dart` imports `Tristate` from `dart:ui`; `SemanticsFlags.isEnabled` uses the `Tristate` type. The test now imports `dart:ui show Tristate` and compares directly to `Tristate.isTrue` and `Tristate.isFalse`. The `isButton`, tap-action, label, and hit-target checks remain independent. Focused format, analyze, and test results are in `correction.log` (all exit 0).

## Deviations / reviewer notes

- Shimmer’s enabled-state checks use the typed `dart:ui` `Tristate` enum, verified in the installed Flutter SDK source (`flutter/lib/src/semantics/semantics.dart` imports `Tristate` from `dart:ui`, and `SemanticsFlags.isEnabled` returns that type). No string representation checks remain.
- A first formatter/analyzer pass exposed only test setup/API issues; these were corrected before final focused verification. Initial combined test runs also hit command timeouts; isolated per-file runs completed.
- Changed test files in this lane: `app_video_viewer_test.dart`, `empty_state_test.dart`, `shimmer_scope_test.dart`, `app_router_test.dart`. `app_dialog_test.dart` and `app_shell_test.dart` were verified without edits. Only this lane's report and `focused.log` were added under the requested evidence directory.
