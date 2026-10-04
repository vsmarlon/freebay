# Global bottom sheets and cancellation UI

Revision tested: `81e8866d980e2783dfe29a53b8eb7ca088e727f5` plus the working-tree changes. Branch: `feat/production-hardening`. Verification logs, exit statuses, and before/after source fingerprints are in `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-20261002-global-sheets`.

## Changes

- `frontend/libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart`: forward native `useSafeArea`, theme/provided background, and a `scrollable` option; calculate the 90% height cap from pre-keyboard constraints, animate IME padding once, keep bottom safe area inside, and use the typography token for the title.
- `frontend/libs/freebay_design_system/lib/components/app_button.dart`: constrain the label to one ellipsized line while retaining its complete semantics label.
- Migrated cancellation, product picker, reaction details, color grid, forward-message sheet, and video composer to the shared sheet behavior. Removed the reaction sheet's duplicated surface wrapper while preserving its 16px content inset. Bounded list bodies own their scrolling; video composer now has one scroll owner. Reused `AppTextField` for product search.
- Added a stateful order-cancellation sheet: explicit localized reason selection, disabled confirm until selection, fixed accessible actions, local duplicate-submit guard, retry without losing selection, and close only after success. Existing six reason values, `cancelOrder(reason)` API, success/refund-pending feedback, and refresh behavior remain; no backend/financial/status/note contract changed.
- Regression coverage includes background, short viewport + keyboard geometry with an expanded body and visible fixed action, narrow button labels at 1.1x with/without icon and full semantics, and cancellation selection/failure retry/success/loading behavior.

## Root cause

The prior implementation measured the cap against the full viewport; keyboard padding then reduced the usable height. Its first correction subtracted the keyboard inset again from constraints already reduced by `AnimatedPadding`, shrinking the short-screen body to 57px.
The fix moves `LayoutBuilder` outside `AnimatedPadding`: available height is computed once from its constraints minus `viewInsets.bottom`, then the 90% cap is applied inside the animated padding.

## RED → GREEN and gates

- Background-color regression before implementation: `flutter test test/design_system/brutalist_bottom_sheet_test.dart --plain-name 'uses the requested background color'` failed (white actual vs red expected; exit 1); final sheet suite passes.
- Geometry regression against the double-subtraction implementation: `flutter test test/design_system/brutalist_bottom_sheet_test.dart --plain-name 'keeps the fixed action visible with a keyboard in a short viewport'` failed as intended (`Expected >100; Actual 57.0`, exit 1); corrected layout passes.
- Button regression against the original unbounded label: `flutter test test/design_system/app_button_text_scaling_test.dart` reported RenderFlex overflows of 104px and 132px (exit 1); fixed implementation passes.
- Focused final run: three suites (sheet 4, button 1, cancellation 2) passed, 7 tests total.
- Latest scoped `flutter analyze --fatal-infos <13 touched Dart files>`: passed, no issues. Latest full `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib`: exit 1 for one unrelated info in pre-existing dirty `lib/main.dart:41` (`curly_braces_in_flow_control_structures`). An earlier full analyze run passed before that dirty file changed.
- Latest `flutter test`: exit 1; 304 passed, 4 failed. Failures are `core/router/cupertino_transitions_test.dart` edge-swipe case, two existing dirty `profile/edit_profile_page_test.dart` pending-response assertions, and `profile/profile_timeline_tabs_test.dart` missing `PROFILE HEADER`; none touch this slice.
- `npm run lint`: passed. `npm test -- --runInBand`: passed, 103 suites / 649 tests.
- `node scripts/ci-check.js`: exit 0. `npm run test:ci-scripts`: passed, 14/14.
- Owned-file Dart format: passed (13 files, 0 changed on the final check). Whole format check remains exit 1 for three unrelated files: `frontend/lib/main.dart`, `frontend/test/features/social/post_details_initial_loading_test.dart`, and `frontend/test/shared/l10n/app_locale_resolution_test.dart`; none was formatted or edited by this task.
- No device, APK build, or database/runtime validation was performed.

## Remaining boundaries and commit

The original cancellation note/role-policy work is explicitly not part of this UI-only slice; no claim is made that cancellation notes or backend financial eligibility rules were implemented. No route, error-system, reply, media-export, backend, migration, dependency, or persisted-data behavior was changed.

No commit was created. The touched tracked caller files (notably `order_detail_page.dart`, `product_picker_sheet.dart`, `chat_video_composer.dart`, and `forward_message_sheet.dart`) already contained substantial unrelated dirty changes before this work. The migrated draw palette is inside a pre-existing untracked `frontend/lib/features/media_editor/` tree. Staging those files wholesale would include unrelated work; the index was left empty rather than risk an incorrect commit. No push was performed.
