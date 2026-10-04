# Flutter UX resume prep slice — 2026-10-02

## Scope and provenance

Ran in `C:\Users\Qiyana\Documents\GitHub\ME\freebay` on the pre-existing dirty tree at `c9808b1`; no revision or clean-tree claim. Before touching owned test files, copied them to `C:\Users\Qiyana\AppData\Local\Temp\opencode\freebay-ux-resume-20261002-owned\` using their relative paths flattened with `__`:

- `frontend__test__features__profile__follow_state_test.dart`
- `frontend__test__features__profile__profile_settings_sheet_test.dart`
- `frontend__test__features__profile__profile_timeline_tabs_test.dart`

No credentials were used. No backend, database, migration, device, ADB, broad Flutter gate, build, or commit was run.

## Test contracts and decisions

- Follow: pending request must be discarded across account switch and late status response must not seed the next session; regression was already added in the dirty tree. Seven focused tests passed. Diff against the pre-edit snapshot shows no follow test changes in this slice, and added account-switch tests/assertions remain intact. No follow provider/source edits.
- Settings sheet: observable contract is drag dismissal/reverse drag, settings scrolling and tap while remaining on profile route/shell. Existing test did not compile due missing `Failure`/`CancelToken`, wrong go_router constructor, and invalid Riverpod inherited-widget lookup. Added the missing imports and changed only the test route constructor to the existing go_router `StatefulShellRoute` custom-container idiom. It now compiles, then fails the existing drag behavioral assertion (`sheet.top` remains 60 after dragging). Production shared-sheet edit is withheld pending parent authorization; this is a real behavioral RED, not a compile/setup failure.
- Timeline tabs: observable contract covers localized labels, shell isolation, horizontal pager gesture boundaries, parent header position during inner scrolling, and independent per-kind scroll offsets. Existing test has mocked empty timelines, so it cannot exercise offset retention; pre-existing dirty changes provide 18-item fixtures and real Portuguese localization. `flutter gen-l10n` was run using the existing `frontend/l10n.yaml`. Generated localization imports compile. A header fixture height/scroll adjustment (500→240, drag -300→-120) was tried, but the test still fails when the header finder disappears during the first timeline scroll check. This does not establish a production bug; profile-tabs production is untouched pending live A30 capture authorization. The failing observable is preserved; no assertion was deleted or weakened.

No test-only seam was added. Existing provider and timeline test layers are the current owners; the needed edit for timeline failure is either fixture/scroll correction or authorized device-led profile-tabs investigation.

## Commands and actual results

Working directory for all commands below: `frontend`.

- `flutter gen-l10n` — exit 0. Output: `Because l10n.yaml exists, the options defined there will be used.` and `"pt": 996 untranslated message(s).` Generated three localization files under `lib/shared/l10n/generated/`; no hand edits.
- `flutter test --no-pub test/features/profile/follow_state_test.dart` — exit 0, `00:00 +7: All tests passed!`
- `flutter test --no-pub test/features/profile/profile_settings_sheet_test.dart` — exit 1 after harness repairs; expected top `> 60.0`, actual `60.0`. Earlier pre-repair run was compile failure, not treated as RED evidence.
- `flutter test --no-pub test/features/profile/profile_timeline_tabs_test.dart` — exit 1; `Found 0 widgets with text "PROFILE HEADER"` at the check after timeline scroll. Same failure reproduced after fixture adjustment.
- `dart format --output=none --set-exit-if-changed test/features/profile/follow_state_test.dart test/features/profile/profile_settings_sheet_test.dart test/features/profile/profile_timeline_tabs_test.dart` — exit 0, formatted 3 files (0 changed).
- `flutter analyze --no-pub test/features/profile/follow_state_test.dart test/features/profile/profile_settings_sheet_test.dart test/features/profile/profile_timeline_tabs_test.dart` — exit 0, `No issues found! (ran in 29.1s)`.

## Remaining blockers

Settings production behavior needs parent permission before touching shared sheet due its many callers. Timeline production profile_tabs remains untouched pending live A30 before-capture authorization; current widget failure alone is insufficient device evidence. Overall slice is not GREEN: both focused widget tests compile but retain behavioral failures.
