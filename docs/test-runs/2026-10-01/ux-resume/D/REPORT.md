# UX resume — feed retry preparation

## Scope and ownership preservation

Before editing, captured SHA-256 for the two authorized feed files:

| File | Pre-edit SHA-256 |
|---|---|
| `frontend/lib/features/social/presentation/widgets/feed_post_list.dart` | `1356CDF0C84BE49AB992DD0951BD7E369A725802A5A9F2F3F323F720FC941866` |
| `frontend/test/features/social/feed_append_retry_test.dart` | `2780F4F72078EAF95600CA42EE200C642411D9B4F8A5BA887E6ADEFC98FD4828` |

The existing working-tree modifications in these files were preserved. In the initial restricted-utility preparation stage, no test file was changed. Before SDK release, the authorized feed test had also received an external update; its resume-stage pre-edit hash is recorded below.

## Observed regression and edit

The existing `failed append keeps posts and offers a deliberate retry` test failed in `integrated-round-1/focused-failures.log`: it could not find the retry control after an append failure. Source tracing confirms the lost persistent retry was in `FeedPostList`; `FeedPage._onScroll` intentionally stops pagination while an error exists. The transient snackbar is therefore not a substitute for a persistent action after it disappears.

Restored the loaded-post error footer in `FeedPostList`, using the existing localized `commonRetry` catalog label, existing `AppButton`, and existing `onRetry` callback. Loaded posts stay rendered. No provider/request policy, empty state, shimmer, refresh, or snackbar behavior changed.

## Verification status

Pre-fix RED evidence is the tester's integrated run at `../integrated-round-1/REPORT.md` and its detailed failure log; the exact assertion reported zero `TENTAR NOVAMENTE` widgets. The fresh post-release run passed both login scales, but the feed case initially failed because the snackbar action and footer had duplicate localized labels. The test now targets the `AppButton` footer explicitly and dismisses the snackbar before tapping it; it retains its current-cursor, retained-post, and retry assertions. An attempt to tap while the snackbar overlay remained visible did not hit the footer; no assertion was weakened.

Results after the final source/test edits:

| Command | Result |
|---|---|
| `flutter test test/features/auth/login_text_scaling_test.dart test/features/social/feed_append_retry_test.dart --reporter expanded` | Exit 0; 3 tests passed. Login+feed output: `D/focused-final.log`. |
| `flutter test test/features/auth/login_text_scaling_test.dart --reporter expanded` | Exit 0; 1.5x and 2.0x cases passed (`D/login-final.log`). |
| `dart format --output=none --set-exit-if-changed lib/features/social/presentation/widgets/feed_post_list.dart test/features/social/feed_append_retry_test.dart` | Exit 0; 2 files, 0 changed. |
| `flutter analyze --fatal-infos lib/features/social/presentation/widgets/feed_post_list.dart test/features/social/feed_append_retry_test.dart` | Exit 0; no issues found. |

The first focused run (`D/focused-initial.log`) had login 1.5x/2.0x pass, and feed failed on the ambiguous retry label. The intervening `dart format --output=none --set-exit-if-changed` found one format change in the authorized feed source; `dart format` then formatted that file. An initial formatter invocation from repository root used frontend-relative paths and failed with `No file or directory found`; the correct invocation from `frontend/` succeeded. A scoped analyzer run initially found an unnecessary import because the test imported all of `core/ui.dart`; the import was narrowed to `show AppButton`, after which the scoped analyzer passed. No tagged probe was needed: the current login 2.0x test passed without any auth source or test edit. No full Flutter suite, device, APK, native, or root gates were run; those remain with the parent/tester. No device/runtime verification is claimed.

## Login scaling owner investigation (read-only; pending runtime diagnostic)

Inspected `LoginPage`, `AuthHeader`, `GoogleAuthButton`, `CenteredFormWrapper`, and the existing 1.5x/2.0x widget test. Earlier integrated evidence recorded a `RenderFlex` horizontal overflow triggered after entering a long invalid email and submitting; its exact owner was not identified in that run. In the fresh post-release run, both login cases passed, so no diagnostic probe or login code change was warranted.


The investigated candidates remain hypotheses only: (1) login remember-me/forgot-password `Row`; (2) `AppTextField` prefix/suffix layout with the validator message; (3) reused `AuthHeader` title/back-button `Stack`. `AuthHeader` also has register/complete-profile callers; `GoogleAuthButton` is used by register. No shared widget or auth file was changed.

## Final owned-file fingerprints

Using the same PowerShell `Get-FileHash -Algorithm SHA256` method as the pre-edit snapshot:

| File | Pre-edit SHA-256 | Final SHA-256 |
|---|---|---|
| `frontend/lib/features/social/presentation/widgets/feed_post_list.dart` | `1356CDF0C84BE49AB992DD0951BD7E369A725802A5A9F2F3F323F720FC941866` | `681D756650380CB7B9DA8ED24506885B03CB9395355EDC51A70E06F8D02BAA01` |
| `frontend/test/features/social/feed_append_retry_test.dart` | `2780F4F72078EAF95600CA42EE200C642411D9B4F8A5BA887E6ADEFC98FD4828` | `FB97C970A16F49E22A1F1C23BDFF98FEC51CECA54DDF5149723052A843FDE04A` |
| `frontend/lib/features/auth/presentation/pages/login_page.dart` | `C62989C4BC13A53B83FAD597B0EBBFA72506A45D2C343FE545B42BA66D1763D6` | `C62989C4BC13A53B83FAD597B0EBBFA72506A45D2C343FE545B42BA66D1763D6` |
| `frontend/lib/features/auth/presentation/widgets/auth_header.dart` | `BE3C623162BB2CE13228F1689EA8AF202D811AE38843B72BC392CA96277C5923` | `BE3C623162BB2CE13228F1689EA8AF202D811AE38843B72BC392CA96277C5923` |
| `frontend/lib/features/auth/presentation/widgets/google_auth_button.dart` | `5C71B90E370B2AD91EBDE0404069200608FA7A3E6C4DDE56B19C3BF6C782EA47` | `5C71B90E370B2AD91EBDE0404069200608FA7A3E6C4DDE56B19C3BF6C782EA47` |
| `frontend/test/features/auth/login_text_scaling_test.dart` | `266051DBC89B5C85704F8217E8806626C8BB6D46BECB2FD7C2CE94E0AEE83A9C` | `266051DBC89B5C85704F8217E8806626C8BB6D46BECB2FD7C2CE94E0AEE83A9C` |

At SDK-release resume, before any test edits in this session, `frontend/test/features/social/feed_append_retry_test.dart` had SHA-256 `A434C3283DBD876A423B1D1ED606B13D648AFA8A7B91BF89B00ED62EF6C3FC50` (captured with the same method). It already contained external edits replacing the earlier test. This session preserved that test and changed only the AppButton import/finder, explicit snackbar dismissal, and visibility settling needed to exercise the persistent footer without the transient snackbar intercepting the tap.
