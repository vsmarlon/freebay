# UX resume — Lane 5 feature tests

**Revision/worktree:** `c9808b1` plus the pre-existing dirty working tree and Lane 5 test edits. Only Lane 5-owned tests and this evidence folder were changed; no production code, generated output, or unrelated WIP was touched. Environment: Windows, Flutter/Dart project under `frontend`; no credentials, external services, DB, device, or provider were used.

## Changes and preserved contracts

- Added generated localization delegates and explicit `pt_BR` locale to affected test apps. Replaced stale assertions that contradicted the current localized/capitalized UI or generic error presentation.
- Updated category/product fixtures to include a `ProductImageEntity` where the tested Hero contract requires an image; duplicate product IDs still must not register duplicate Hero tags.
- Chat assertions retain deletion undo, reverse transcript behavior, rebind/theme changes, one `clientId` per send/retry, and double-tap protection. HTTP retry limits/cancellation and wallet/Connect state assertions are unchanged. Story/media-editor tests were not weakened or skipped.
- `story_viewer_interaction_test.dart`'s `@override` is valid: `StoriesRepository.viewStory(String)` returns `Future<Either<Failure, void>>`.

## Verification

- Supplied whole-suite baseline: `208 passed / 75 failed`, exit `1`, from `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-tests-baseline.log`.
- Initial Lane 5 focused sweep: `22 passed / 28 failed`, exit `1`; the large majority were test apps missing generated localization delegates. Subsequent focused iterations are preserved in the Temp files; final owned-group command and output are below.
- `flutter test test/features/chat/chat_list_tile_test.dart test/features/chat/conversation_deletion_undo_test.dart test/features/chat/new_chat_page_test.dart test/features/chat/repro_conversation_open_test.dart test/features/onboarding/welcome_setup_page_test.dart test/features/product/category_gesture_test.dart test/features/product/product_filter_bar_test.dart test/features/product/product_hero_tag_test.dart test/features/product/product_load_more_error_test.dart test/features/wallet/wallet_controller_test.dart test/shared/services/http_client_retry_test.dart test/features/stories test/features/media_editor` — **exit 0**, `48` tests passed. Log: [`focused-tests.log`](focused-tests.log).
- `dart format` on all Lane 5-owned test files/directories — exit `0`; formatted 19 files, 4 changed in the earlier formatting pass, then 0 changed on the final pass. Final `dart format --output=none --set-exit-if-changed` on the same list — **exit 0**, `19 files` unchanged.
- `flutter analyze` on all Lane 5-owned test files/directories — **exit 0**, `No issues found! (ran in 14.3s)`. Log: [`analyze.log`](analyze.log).
- `flutter test test/features/auth/login_text_scaling_test.dart` — **exit 1**, 1 passed / 1 failed. At 2.0x, the test observes `A RenderFlex overflowed by 10.0 pixels on the right.` at `login_page.dart:252` in the localized account-question/sign-up `Row`; the 1.5x case passes. This is a production accessibility/layout defect, not a test harness failure. Per lane scope it was not fixed here; please assign the production fix to the owning auth lane and retain this regression.

## Deviation / reviewer follow-up

Lane 5 is not entirely green because the text-scaling test surfaced the real LoginPage overflow. Root cause is the unflexed horizontal row combining the uppercased account prompt and sign-up action at increased text scale. Auth sibling search found the exact prompt/action pair only in `LoginPage`; `RegisterPage` has a separate Google action, not this pair. No assertion was removed or weakened. No production change was authorized in this lane.

Owned test files changed: `frontend/test/features/auth/login_text_scaling_test.dart`; `frontend/test/features/chat/{chat_list_tile,conversation_deletion_undo,new_chat_page,repro_conversation_open}_test.dart`; `frontend/test/features/onboarding/welcome_setup_page_test.dart`; `frontend/test/features/product/{category_gesture,product_filter_bar,product_hero_tag,product_load_more_error}_test.dart`; `frontend/test/features/wallet/wallet_controller_test.dart`. Existing Stories/media-editor suites and `http_client_retry_test.dart` were in scope and remain unchanged.
