# Flutter design-token integration and gates

**Date:** 2026-10-01  
**Branch / revision:** `feat/production-hardening` / `c9808b106c3d53f07837542e93f25fd52c6bfbe5` (unchanged)  
**Working tree:** pre-existing dirty integration/WIP preserved. Pre-edit status snapshot SHA-256: `CBD1811415F2792E966C6A7E27478B0D6A67242365ACED198B207E8E765B18AE`; final snapshot SHA-256: `CBA7504490BC288EAD565A1A16B08E701B3F75771B194288E7245DD6532E21D2`.  
**Environment:** Windows, frontend working directory; credentials omitted.

## Owned changes

- `frontend/lib/features/orders/presentation/pages/orders_tab.dart`: use `Spacing.md` for the raw `EdgeInsets.all` values.
- `frontend/lib/features/profile/presentation/widgets/profile_tabs.dart`: use spacing tokens for the profile timeline insets.
- `frontend/lib/features/social/presentation/widgets/feed_post_list.dart`: use spacing tokens for the loading item insets.
- Story-page source was moved during this run from `frontend/lib/features/social/presentation/widgets/story_page.dart` to `frontend/lib/features/stories/presentation/widgets/story_page.dart` by concurrent working-tree activity. The token replacements in the new untracked path use `AppColors.onPrimary` for the media-overlay whites. The moved source has not been reverted or relocated.

No behavioral changes or tests were added. `scripts/ci-check.js` initially reported the six known D3/D4 additions across these owned files. The final run still exits 1 because of unrelated D3/D4 additions in media-editor and story-creation files; none of the four owned token findings remain.

## Commands and results

All logs/manifests are alongside this report.

| Command | Exit | Result |
|---|---:|---|
| `node scripts/ci-check.js` (initial; `design-ratchet.log`) | 1 | Reproduced six additions: orders D4, profile D4, feed D4, and three story-page D3 matches. |
| `dart run build_runner build --delete-conflicting-outputs` | 0 | Built successfully; generator reported “wrote 20 outputs.” Existing generated artifacts changed and deleted generated story entity outputs were noted; no generated file was manually edited or restored. |
| `dart format --output=none --set-exit-if-changed lib test libs/freebay_design_system/lib` (`format-final.log`) | 1 | Existing working-tree formatting drift: 118 of 605 files reported changed. The three still-present owned source paths were formatted directly; story-page was moved during the run. |
| `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` | 1 | 469 issues. Includes extensive undefined localization members, invalid const expressions, and unrelated test/source errors. Full output: `analyze.log`. |
| `flutter test` | 1 | 132 tests passed; 56 failed to load/run, with compilation errors including missing localization members. Full output: `test-suite.log`. |
| `flutter build apk --debug` | 1 | No APK produced. Compile errors include missing localization members, invalid const expressions, unrelated nullable/type/member errors, and `orders_tab.dart:178` calling `l10n(context)` under a `const` widget. Full output: `apk-build.log`. |
| Focused order/profile/feed/story widget tests | 1 | Blocked at compilation by the same integration errors. Initial focused run also preceded codegen and reported missing provider `.g.dart` files. The historical `test/features/social/story_viewer_interaction_test.dart` path no longer existed after concurrent move; reran using `test/features/stories/story_viewer_interaction_test.dart`. |
| `node scripts/ci-check.js` (final; `design-ratchet-final4.log`) | 1 | No additions remain for the four owned token files. Remaining output lists unrelated media-editor and story-creation additions. |

The exact commands, timestamps, and exit codes are in the corresponding JSON manifests. The CI runner logs redact common credential patterns.

## Blockers / limits

- Combined Flutter gates are blocked by the pre-existing/integrated dirty tree; this lane did not alter localization, provider, generated, baseline, dependency, or unrelated feature sources to repair those failures.
- The APK build failed, so there is no APK artifact/evidence.
- Codegen ran after the initial focused attempt and produced generated output in the already-dirty tree. Generated changes were left in place; no cleanup/restore was performed.
- During the run, the social story-page path became deleted and a story-feature path appeared untracked. This concurrent move is preserved and should be reconciled by the integration owner.
- No device, runtime database, or production behavior was verified.
