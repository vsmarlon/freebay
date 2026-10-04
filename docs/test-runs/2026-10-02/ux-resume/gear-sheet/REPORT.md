# Gear settings sheet drag repair — 2026-10-02

## Scope and provenance

Worked in `C:\Users\Qiyana\Documents\GitHub\ME\freebay` on the pre-existing dirty tree at `c9808b1`; no clean-tree or commit claim. Before modifying the shared primitive, snapshotted `frontend/libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart` to `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-20261002-owned\frontend__libs__freebay_design_system__lib__components__brutalist_bottom_sheet.dart`. The pre-existing profile settings test was also copied to that owned snapshot folder earlier in the session. No credentials, backend, DB, device, ADB, broad gates, or build were used.

## Contract and root cause

Observable contract: a long settings sheet can be partially dragged down continuously and dismissed by swiping downward; reverse drag leaves it open; users can still scroll/tap the settings contents, and the shell route remains `/profile`. Credible regression: a vertical `SingleChildScrollView` wrapped the entire `BrutalistSheetScaffold`, including the drag handle and title. When content overflowed the modal's 90% height, this scrollable won the vertical gesture arena, so the native modal BottomSheet did not follow the finger. Existing design-system coverage used a short, non-overflowing child and could not detect that regression. No test-only production seam was added.

Evidence before production edit: `profile_settings_sheet_test.dart` failed after a fair handle/title drag at `originalTop + 28`; the expected sheet top `> 60.0` remained `60.0`. Letting the same gesture continue far enough dismissed the sheet, confirming the problem was continuous/native gesture ownership rather than a permanently un-dismissible route. A new long-content design-system regression was then run against the snapshotted primitive: it failed because `Row 0` remained present after swiping the title down 500px (exit 1). After the fix, both focused suites passed, including the profile reverse-drag, content scroll/tap and stable-route checks.

## Change

- `frontend/libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart`: move the scroll view inside the scaffold's flexible body; the existing native modal drag handle/title remain outside that competing scrollable. Preserve the default native modal drag behavior, 90% height limit, keyboard inset animation, safe area, existing title/handle options, colors and child padding. No caller APIs or call sites changed. The caller search found the existing 18 `showBrutalistSheet` call sites across app features; all remain untouched.
- `frontend/test/design_system/brutalist_bottom_sheet_test.dart`: cover downward dismissal for a long overflowing body initiated at the title/handle area. Existing short-body test remains.
- `frontend/test/features/profile/profile_settings_sheet_test.dart`: repaired the existing harness earlier in this slice (missing imports, unsupported `StatefulShellRoute.indexedStack` custom container, invalid Riverpod inherited lookup removed). Its continuous drag now samples after moving past touch slop (two 36px move events), then retains the original dismissal, reverse-drag, settings-scroll/tap and route assertions. No assertion was weakened; this makes the partial-motion assertion test actual movement after the gesture recognizer's start threshold.

## Exact commands and results

Working directory for commands below: `frontend`.

- `flutter test --no-pub test/features/profile/profile_settings_sheet_test.dart` before primitive edit — exit 1, expected top `> 60.0`, actual `60.0`.
- `flutter test --no-pub test/design_system/brutalist_bottom_sheet_test.dart` with the snapshotted pre-fix primitive and new regression — exit 1; `Expected: no matching candidates`, but `Row 0` remained; failure at the post-swipe dismissal assertion.
- `flutter test --no-pub test/design_system/brutalist_bottom_sheet_test.dart test/features/profile/profile_settings_sheet_test.dart` after the fix — exit 0, `00:36 +3: All tests passed!` (final post-format run).
- `dart format libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart test/design_system/brutalist_bottom_sheet_test.dart test/features/profile/profile_settings_sheet_test.dart` — exit 0, formatted 2 files; 3 files processed.
- `dart format --output=none --set-exit-if-changed libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart test/design_system/brutalist_bottom_sheet_test.dart test/features/profile/profile_settings_sheet_test.dart` — exit 0, 0 changed.
- `flutter analyze --no-pub libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart test/design_system/brutalist_bottom_sheet_test.dart test/features/profile/profile_settings_sheet_test.dart` — exit 0, `No issues found! (ran in 167.8s)`.

## Limits

This is focused widget evidence, not device evidence. The prior profile timeline/header issue remains outside this authorization; `profile_tabs.dart` and its test were not edited during this continuation. No whole-frontend suite/build or every-caller runtime matrix was run. `flutter gen-l10n` from the preceding slice emitted the generic Portuguese catalog's untranslated count; it did not change ARBs, and this report makes no translation coverage claim.
