# Post detail initial loading regression — 2026-10-02

## Provenance and behavior

- Branch: `feat/production-hardening`; starting HEAD: `81e8866` (full SHA in the external evidence directory). The working tree was extensively dirty before this task; this is not a clean-checkout or integrated-branch result.
- Root cause: `PostDetails.build` returned `PostDetailsState()` with `isLoading == false`.
- Since data loading was deferred with `Future.microtask`, the page's missing-post predicate could paint “Post não encontrado” before the request marked the state loading.
- Fix: initial provider state now has `isLoading: true`; no page guards, delay, or generated code changes.

## Regression contract

`post_details_initial_loading_test.dart` listens to the real generated provider with typed fake use cases and a held post-request `Completer`. It asserts loading on the immediate read, before yielding a microtask and while the request remains pending, then resolves a real `PostEntity` and checks loading/post/error. Existing `post_details_comments_test.dart` awaited settled state and therefore did not cover the first frame.

The first attempted RED command had a test compilation error (`Failure` import/type setup), so it is explicitly not counted as RED. After correcting the test setup:

- `flutter test test/features/social/post_details_initial_loading_test.dart --reporter expanded` before the production fix: **exit 1**, intended assertion failed (`Expected: true`, `Actual: <false>` at the immediate loading assertion).
- Same command after the fix: **exit 0**, 1 test passed.
- `flutter test test/features/social/post_details_comments_test.dart --reporter expanded`: **exit 0**, 4 tests passed.

## Full gates

Exact logs and command result list are in `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-20261002-instagram-investigation` (not committed; no secrets included).

| Command (working directory) | Exit | Result |
|---|---:|---|
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` (`frontend`) | 1 | Check-only formatter reported 4 files needing formatting: provider, this test, pre-existing `test/features/payments/payment_page_test.dart`, and pre-existing `test/shared/l10n/app_locale_resolution_test.dart`. This command did not write them. |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` (`frontend`) | 0 | No issues found. |
| `flutter test` (`frontend`) | 1 | 293 total; 288 passed, 5 failed: two payment-page scaling cases, two edit-profile ownership/draft cases, and one profile timeline tabs case. Full output in external `flutter-test.log`. |
| `npm run lint` (`nest-backend`) | 0 | Passed. |
| `npm test -- --runInBand` (`nest-backend`) | 0 | 103 suites / 649 tests passed. |
| `node scripts/ci-check.js` (repository root) | 0 | Passed. |

No Flutter build, native device journey, or profile/performance validation was run; they are not claimed. No backend application source changed.

## Scope caveat

The social provider and many other files were already dirty. External `status-before.txt`, `provider-before.patch`, and `head-before.txt` identify the baseline captured before edits. The provider's pre-commit working-tree hash differed from its captured pre-edit hash because the failed `lint-staged` run could not restore partially staged content. I verified that removing this task's one-line change and normalizing line endings reproduced the exact pre-edit SHA-256, then restored the provider to that baseline plus the owned line. The staged provider hunk is independently based on `HEAD` and contains only that line. The payment test was already dirty before the formatter check; the check itself did not write it. The owned changes are the initial-state argument, new regression test, and this report.

## Commit attempt

`git commit -m "fix(social): avoid transient post-not-found state"` was attempted once. The hook started `lint-staged`, formatted its staged Dart production file, then failed while restoring the partial-staged provider: `Unstaged changes could not be restored due to a merge conflict!`. Hook exit was 1; the later raw-route check and hook's `node scripts/ci-check.js` did not run. No hook was bypassed and no further hook was run. The provider's staged index blob is now restored to the exact single-line `HEAD` hunk and `git diff --cached --check` passes; however, commit remains blocked rather than retrying hooks against the shared dirty working tree.

## Owned test cleanup follow-up

The test file was formatted on its own; no other Dart file was passed to the formatter. Results after formatting:

- `dart format test/features/social/post_details_initial_loading_test.dart`: **exit 0**, 1 file formatted.
- `flutter test test/features/social/post_details_initial_loading_test.dart --reporter expanded`: **exit 0**, 1 test passed.
- `flutter test test/features/social/post_details_comments_test.dart --reporter expanded`: **exit 0**, 4 tests passed.

At this follow-up the index was confirmed empty before the commands and remains unstaged; HEAD is unchanged. The provider's SHA-256 was `4F8ECEA8C4A803D360360D6571D8E355331F4435505139B728341C3791796547` before and after these test-only cleanup commands.
