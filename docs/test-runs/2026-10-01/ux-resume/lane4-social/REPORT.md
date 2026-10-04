# Lane 4 social/profile resume

## Scope and test-audit contracts

Only the parent-authorized tests and the approved `follow_status_provider.dart` fix were touched; all other dirty work remains untouched. The current source changes and their observable contracts:

| Test(s) | Observable regression protected / diagnosis |
|---|---|
| `profile/follow_state_test.dart` | Optimistic follow/unfollow state, authoritative response, rollback, duplicate request suppression, and following-feed reset. The fake method signatures match `FollowService` and `SocialRepository`; tests expose a production Riverpod initialization defect (details below). |
| `profile/profile_timeline_tabs_test.dart` | Three timeline scopes, horizontal paging that does not change shell branch, vertical scroll retention and independent cursors. Explicit pt-BR now matches current generated locale copy (`profileRepostsTab` is “Republicações”, not “Reposts”). |
| `profile/saved_posts_page_test.dart`, `social/saves_provider_test.dart` | Preserve saved content on refresh failure; successful cross-screen unsave updates the saved list; failed unsave retry/rollback remains separately asserted. Empty-state assertion now uses current generated copy (“NENHUMA PUBLICAÇÃO SALVA”). |
| `social/deletion_undo_test.dart` | Story/post/highlight undo, delayed delete commit and committed-deletion behavior. No changes; passes. |
| `social/feed_append_retry_test.dart` | Exercises the real `FeedPage` consumer: retained post plus snackbar retry after append failure, then verifies retry dispatches the current cursor. The earlier `FeedPostList`-only test was the wrong boundary; `FeedPage` already owns the snackbar retry action. |
| `social/feed_provider_test.dart` | Cursor pagination and recovery, stale-scope response rejection, deduplication and refresh continuity. The repository fake's `getFeed` signature matches its production owner; test now injects anonymous auth rather than invoking the real auth controller/plugin. |
| `social/feed_post_list_loading_test.dart` | Initial skeleton loading, long content at 1.5x/2x scale and no layout exception. The localized copy finder opts into rich text. The exact nine-block assertion is retained; its test viewport is tall enough to build the three lazy placeholder rows. |
| `social/post_details_comments_test.dart` | Comment-count clamping and no-replies/replies indicators. Explicit pt-BR setup. |
| `social/post_search_error_test.dart` | Retryable search error is distinct from empty results. Explicit pt-BR setup. |
| `refactor_regressions/product_form_fields_test.dart` | Existing controllers, localized labels and condition callback. The file already had app localization delegates; its root cause was no explicit supported locale, so set pt-BR only. |

Security/privacy, account isolation, timeline scope, pagination cursor recovery, rollback, concurrency, deletion undo and accessibility-related assertions were not removed or weakened. The retry assertion and shimmer coverage are described above; neither has been deleted.

## Results and diagnosis

Supplied whole-suite baseline: `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-tests-baseline.log`, exit 1, 208 passed / 75 failed. Required pre-edit snapshot remains `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-20261001-start`.

Individual diagnostic output is in `C:\Users\Qiyana\AppData\Local\Temp\opencode\lane4-<test-file>.log`; grouped pre-edit output is `freebay-ux-resume-lane4-before.log`. Key evidence:

1. Localization setup caused null checks in widget build (`AppLocalizations.of` with no localization scope) and cascading absent text/widget assertions. Explicit locale and `AppLocalizations` plus Flutter SDK material/widgets/cupertino delegates fixed the affected tests. Do not infer language from platform fallback in widget tests.
2. `feed_provider_test.dart` did not override `authControllerProvider`. A production auth provider was therefore initialized and `AuthSessionLifecycle` attempted the secure-storage `delete` method, yielding `MissingPluginException`. The test concerns feed request pagination, not auth storage; it now supplies existing `TestAuthController(null)`. All four feed-provider cases pass; cursor/response assertions remain intact.
3. The original three-row shimmer expectation counted offscreen descendants despite a lazy `SliverList.builder`; the widget's itemBuilder supplies exactly three blocks per row, with viewport lazy construction. The test now requires at least three visible blocks and still rejects a progress spinner.
4. Current generated pt-BR strings exposed stale English/mismatched expected labels for profile reposts and saved-post empty state. Assertions now match the selected supported locale and exact current ARB values; no broad copy rewrite was made.
5. `FollowStateNotifier.build` previously called `ref.read(followsInFlightProvider.notifier).clear()` on owner transition (`frontend/lib/features/profile/presentation/providers/follow_status_provider.dart`). Riverpod's RED failure proved this cross-provider notification during provider initialization invalid. The minimal fix removes that write and makes `FollowsInFlightNotifier.build` watch the same selected auth owner; its own state resets to empty on owner change. Explicit `clear`, `_sessionId`, and `_inFlight` guards remain. A focused test also covers a pending follow completion after switching accounts: spinner/status state is cleared, the stale completion returns false, and cannot repopulate the new account's state. Existing four RED cases plus the new transition RED passed before the fix, then the full follow test passed.
6. The first append-retry test composed `FeedPostList` directly and therefore omitted its actual owner, `FeedPage`. Inspection of `FeedPage` (`frontend/lib/features/social/presentation/pages/feed_page.dart:98-100,106-114`) shows `ref.listen` displays a retryable snackbar while retained posts remain visible; `_retry` calls `_loadCurrentFeed(refresh: posts.isEmpty)`, so an append retry keeps the current cursor. The test now uses this consumer and verifies the retained post and cursor sequence `[null, 'cursor-1', 'cursor-1']`. It passes. **No FeedPostList or FeedPage production change was needed.**
7. The exact shimmer count was restored. A tall logical viewport (`devicePixelRatio = 1`, `800x1400`) allows all three lazy rows, so all nine shimmer blocks are mounted without forcing production eagerness. The dedicated assertion passes.

## Verification

Final focused command (from `frontend`):

```powershell
flutter test test/features/profile/follow_state_test.dart test/features/profile/profile_timeline_tabs_test.dart test/features/profile/saved_posts_page_test.dart test/features/social/deletion_undo_test.dart test/features/social/feed_append_retry_test.dart test/features/social/feed_provider_test.dart test/features/social/feed_post_list_loading_test.dart test/features/social/post_details_comments_test.dart test/features/social/post_search_error_test.dart test/features/social/saves_provider_test.dart test/refactor_regressions/product_form_fields_test.dart
```

The grouped command exited 0 with all cases in the eleven authorized files passing. Exact output: `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-lane4-amended.log`. A later rerun exited 1 before executing tests because concurrent dirty work fails compilation in unowned `lib/shared/widgets/platform_wallet_payment_button.dart:31`: `The getter 'paymentWalletUnavailable' isn't defined for the type 'AppLocalizations'.` Output: `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-lane4-amended-final.log`. That file was not edited. Focused follow green output is `lane4-follow-green.log`; the tall-viewport exact-nine shimmer test passed independently in `lane4-shimmer-tall-viewport2.log`.

```powershell
dart analyze lib/features/profile/presentation/providers/follow_status_provider.dart <the same eleven test paths>
```

Exit 0: no issues found.

```powershell
dart format --output=none --set-exit-if-changed <the same eleven test paths>
```

Exit 0: 12 files, 0 changed on the final format check. A focused `flutter test test/features/social/feed_provider_test.dart` also exited 0 after correcting its auth fixture. Full suite, build, codegen, device, database and external-service checks were not run, per instruction.

## Changed files and remaining review

Lane edits were confined to the authorized test files, the approved provider production fix, and this report. `deletion_undo_test.dart` was already dirty in the starting worktree and was not changed by this lane:

- `frontend/test/features/profile/profile_timeline_tabs_test.dart`
- `frontend/test/features/profile/follow_state_test.dart` (preserved prior regression assertions; added account-transition completion coverage)
- `frontend/test/features/profile/saved_posts_page_test.dart`
- `frontend/test/features/social/feed_append_retry_test.dart`
- `frontend/test/features/social/feed_provider_test.dart`
- `frontend/test/features/social/feed_post_list_loading_test.dart`
- `frontend/test/features/social/post_details_comments_test.dart`
- `frontend/test/features/social/post_search_error_test.dart`
- `frontend/test/features/social/saves_provider_test.dart`
- `frontend/test/refactor_regressions/product_form_fields_test.dart`
- `frontend/lib/features/profile/presentation/providers/follow_status_provider.dart` (approved lane amendment)
- `docs/test-runs/2026-10-01/ux-resume/lane4-social/REPORT.md`

`follow_state_test.dart` had a pre-existing dirty change at lane start; its existing assertions were preserved and the approved pending-session case was added. `deletion_undo_test.dart` also had pre-existing dirty changes and was not edited; its cases pass. The only production change is the approved follow-status provider fix. Feed retry was verified at the owning consumer; no inline list UI was added.


