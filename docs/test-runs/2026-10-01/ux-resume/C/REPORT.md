# Deferred follow-status seed across account switch

## Scope

The follow-status response was validated for account A before a scheduled microtask wrote it into the shared follow-state provider. Account B could become current before that callback, allowing A's status to seed B's state; the same callback could also read through a disposed provider ref. The existing pending-*mutation* account-switch test did not cover this: it exercises `FollowStateNotifier.toggleFollow`'s session token, not the separately deferred read-status seed.

The regression uses a real `ProviderContainer`, switchable auth controller, and controlled `FollowService.getFollowStatus` futures. It completes A's status then schedules B's auth change before the deferred seed. A second status request remains pending while the test checks no A status is in shared follow state, then completes with B's distinct status. The service fake is only the HTTP boundary; no provider behavior is mocked.

## RED / GREEN

- `flutter test test/features/profile/follow_state_test.dart --reporter expanded` before the production guard, with the controlled A→B scheduling sequence: **RED for the intended regression**. `seed-race-probe.log` records `Expected: empty; Actual: {'target-user': Instance of 'FollowStatusResponse'}`. The session-account identity was B, so this proves A's deferred response seeded shared state after the switch.
- Production now rechecks `ref.mounted` and the current auth owner inside the scheduled microtask before `seedStatus`. This leaves the HTTP request/result contract unchanged and performs no cross-provider write during provider initialization.
- After adapting the regression to leave a B request pending, rerunning the focused test was **blocked during compilation** by concurrent localization/generated-source mismatch: `profileReportUser`, `profileReportSpam`, `profileReportFraud`, `profileReportHarassment`, `profileReportFakeAccount`, `profileReportImpersonation`, `profileReportNudity`, `profileReportBlackmail`, `profileReportFalseAdvertising`, `profileReportOther`, and `profileReportSubmitted` are missing from `AppLocalizations`, referenced by `frontend/lib/features/profile/presentation/pages/user_profile_page.dart`. `seed-race-green.log` preserves that result. This is outside the owned files; GREEN is not claimed.
- The run captured in `seed-race-red.log` was also blocked at compilation by that same external localization mismatch. The earlier initial probe (`seed-race-probe.log`) is the valid behavioral RED.

## Other checks

- `dart format --output=none --set-exit-if-changed lib/features/profile/presentation/providers/follow_status_provider.dart test/features/profile/follow_state_test.dart` — exit 0, 2 files unchanged.
- `flutter analyze --fatal-infos lib/features/profile/presentation/providers/follow_status_provider.dart test/features/profile/follow_state_test.dart` — exit 0, `No issues found!`.
- No sibling Flutter tests, full suite, build, device test, commit, dependency/schema change, or generated-file edit was performed.

## Ownership / limits

Only the approved provider, its focused test, and this C evidence directory were touched by this lane. The surrounding tree contains concurrent work; none of it was reverted or edited. Final SHA-256: provider `5E20CBA7B3AF4D3238E973706BF8C0F19FED433074B98B5A4C2C0D308FABA1A7`; test `5EA04C2A587498EE596F9C5B2AE9F8F0EACCAF576384D316FA71A15EA0C0694D`. Re-run the focused test to establish GREEN when the unrelated localization compile blocker is resolved.
