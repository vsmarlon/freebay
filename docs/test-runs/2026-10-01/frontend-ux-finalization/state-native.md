# UX finalization — shared state and native source audit

**Scope:** shared cache lifecycle, social action reconciliation, and native image compositor source. This worker did not perform device actions. Workspace already contained broad dirty changes from parallel UX work; no reset, commit, push, migration, generated-file edit, or unrelated cleanup was performed.

## Changes and evidence

- `StorageService.clearUserCache` previously incremented its generation and returned when the Hive box was closed, leaving persisted user data intact at logout. Added a closed-box reopen path and serialized cache writes/deletes/purges. Cache-write generations are checked immediately before persistence, so an earlier queued write cannot repopulate data after a purge; malformed-entry cleanup is also ordered and generation-checked.
- Added a real-Hive persistence regression test for clearing a closed box. Its RED run failed on the expected surviving `alice:profile` entry; after the fix, all three cache tests pass, including the pending-write/purge case.
- Like/save/repost reconciliation previously removed an override/version for a fresh entity while its mutation request was still in flight. The matching completion was then discarded, losing the authoritative count/state. Reconciliation now leaves in-flight keys for the mutation completion to settle. Added a like regression test; its RED run failed because the mutation returned `false` after reconciliation.
- Audited the Android and iOS native compositor paths, Dart channel payload, editor integration test, and iOS project source registration. Source-level contract is aligned for channel/method names, payload/result bytes, validation limits, image orientation/downsampling, draw/erase/filter/rotation/text operations, and asynchronous native work. No source-only finding justified a speculative native edit. Pixel correctness still needs execution on Android and iOS; no device was used.

## Verification

- `flutter test test/shared/services/storage_service_cache_test.dart` before cache fix: **failed as intended** — `Expected: false; Actual: <true>` at the new closed-box persisted-cache assertion.
- `flutter test test/shared/services/storage_service_cache_test.dart` after fix: **passed**, `All tests passed!` (3 tests).
- `dart format --output=none --set-exit-if-changed` on the six changed Dart source/test files: **passed**, `Formatted 6 files (0 changed)` after applying targeted formatting.
- `flutter test test/features/social/social_action_concurrency_test.dart` before reconciliation fix: **failed as intended** — expected mutation result `true`, actual `false` at the new in-flight reconciliation regression.
- `flutter test test/features/social/social_action_concurrency_test.dart test/shared/services/storage_service_cache_test.dart` after source fix: **blocked before social tests ran** by an existing parallel-tree compile error: `lib/features/social/data/repositories/social_repository.dart:49:9: Error: Type 'SocialRepositoryStories' not found.` The storage tests in that combined invocation did run and passed; that run's overall exit status was 1. This is not a valid GREEN for action-provider behavior.
- Full Flutter format/analyze/test/build and native integration/device checks were intentionally not run: the coordinating instructions reserve full gates until all five source workers freeze, and prohibit device actions.

## Deviations and remaining checks

- Cache scope was extended minimally to serialize cache mutations and fence malformed-entry deletion because simply reopening the box would leave the pending-write/logout race unresolved.
- Social-action fix is implemented but awaits rerunning its focused test after the missing `SocialRepositoryStories` definition is resolved in the parallel integration.
- Native audit is source-only, not proof of pixel parity. Run the compositor integration test on both Android and iOS after integration settles; preserve the user app/device state meanwhile.
