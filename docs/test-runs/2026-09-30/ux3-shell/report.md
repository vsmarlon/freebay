# UX3 profile timelines and shared scroll chrome

- **Revision:** `37e1100` (implementation), based on `4558181`; includes earlier shared scroll physics/gesture commit `6f2c6cd`.
- **Environment:** Windows Flutter widget-test environment; no device, backend, account, or provider credentials used.
- **Fixture/reset:** GoRouter with five shell branches, real `ProfileTabs` inside branch 4, and fake Dio `HttpClientAdapter` serving terminal cursor pages. Tests use no database. A temporary empty `frontend/.env` was required by the pubspec asset declaration and removed after runs.
- **RED (profile tabs):** `flutter test test/features/profile/profile_timeline_tabs_test.dart` failed against the original UI at the expected missing `REPOSTS` tab assertion. This was an observable UI failure, not a fixture or compile failure.
- **RED (reverse chat scroll):** `flutter test test/core/components/hide_on_scroll_test.dart --plain-name "reversed chat scroll"` showed the reversed list's actual user drag uses `AxisDirection.up` with positive logical scroll delta. Inverting that delta incorrectly left chrome shown (`Expected: <0>, Actual: <1.0>`). The fix preserves the reverse-list's anchor/logical direction: positive means moving away from chat bottom; negative means returning to bottom.
- **GREEN focused command:** `flutter test test/features/profile/profile_timeline_tabs_test.dart test/features/profile/user_posts_pagination_test.dart test/core/components/app_shell_test.dart test/core/components/hide_on_scroll_test.dart` — `00:14 +14: All tests passed!` (exit 0).
- **Coverage:** the profile-shell test enters all 3 timeline queries through the HTTP adapter (`posts`, `reposts`, `products`); actual horizontal drags reach all tab pages, overswipe at both edges without switching the shell branch, and retain the shared profile-header vertical offset while switching tabs. The repository test verifies server-side `kind=products` transport. Scroll tests exercise shell-header hide/reveal, keyboard-inset scroll suppression, reverse-list hide/reveal, and verify programmatic scrolling does not hide chrome. Existing app-shell drag/drawer cases remain green.
- **Static check:** `flutter analyze` on the 19 changed production/test Dart paths — `No issues found!` (exit 0).
- **Formatting:** `dart format` on touched Dart files — completed.
- **Diff hygiene:** `git diff --ignore-space-at-eol --check` — no issues.
- **Device/E2E status:** widget and fake-HTTP evidence only; no real-device/IME interaction, performance profile, or server database test was run here. The backend's real database E2E owns server filtering semantics; mobile smoothness and native IME layout remain device checks, not claimed passed.
- **RED/GREEN caveat:** the reverse-chat focused regression was authored after an initial code attempt, but the failing run revealed the logical-direction bug and the corrected code passed. This task started after an earlier shell implementation commit; that prior shell nested-pager test was not run RED against the baseline and remains documented in the prior commit history.

## Earlier shared scroll-shell slice

- **Revision:** `6f2c6cd` (`4558181` base)
- **Environment:** Windows, Flutter widget-test environment; no device, backend, or provider credentials used.
- **Fixture/reset:** `flutter test` creates an in-memory GoRouter with five shell branches; no database state.
- **RED:** Not observed. Production edits were made before adding the focused regression test; this diverged from the required RED/GREEN order.
- **Focused command:** `flutter test test/core/components/app_shell_test.dart` from `frontend/`
- **Expected:** nested horizontal timeline paging remains inside its child and does not change the outer shell branch; existing shell navigation and drawer tests remain green.
- **Actual:** `00:00 +6: All tests passed!` (six tests).
- **Exit status:** 0.
- **Static check:** `flutter analyze lib/core/components/hide_on_scroll.dart lib/core/components/app_shell.dart lib/main.dart test/core/components/app_shell_test.dart` — `No issues found!` (exit 0).
- **Formatting:** `dart format` on the four changed Dart files — completed, 4 files formatted (exit 0).
- **Diff hygiene:** `git diff --check` — no output (exit 0).
- **Known limit:** Widget tests do not prove real-device finger tracking, nested profile timeline gestures at both ends, chat chrome, keyboard behavior, or performance. Those requested timeline/chat changes were not implemented in this slice.
- **Setup note:** initial test failed because the checkout lacked the configured `frontend/.env` asset. A temporary empty placeholder was used for the widget test and removed afterward; it is not part of the commit.
