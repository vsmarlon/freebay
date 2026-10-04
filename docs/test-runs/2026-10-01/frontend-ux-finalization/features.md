# Feature extraction — stories and media editor

## Scope and source revision

Extracted the frozen Stories and image-editor slices after executor ownership began. The workspace started at `c9808b1` with extensive unrelated dirty work; no pre-existing work was reset or committed. Android/iOS compositor sources and registrations were left untouched.

## Changes

- Stories now owns its story entity and unchanged Freezed/JSON parts, concrete `StoriesRepository` HTTP implementation, read providers, submission coordinator, story pages/widgets, and `stories.dart` public API. Story endpoints were removed from `SocialRepository`; feed pagination/post state stays in Social. Routes, profile/feed/auth invalidation, integration references, and story tests now use the Stories owner.
- `media_editor` now owns the Dart editor page, operation/result models, paint/toolbar/views, filters/palette, and compositor adapter. `media_editor.dart` exports its route/page-facing API. Chat and story/post composer consumers and router imports point to the new owner. Native platform channel implementations remain at their existing Android/iOS paths.
- Added an in-flight pagination guard in `Feed` so repeated load-more requests cannot issue concurrent requests while the first page request is pending. Existing feed result/error/cursor behavior is unchanged; a focused assertion was added to the existing cursor test without removing assertions.
- Moved story unit tests and the editor export test into their feature directories; updated `perf_test.dart` and the native compositor integration-test imports.

## Behavior preservation

Stories repository methods retain the existing paths, multipart fields, media compression/MIME selection, response decoding, and failure mapping from `social_repository_stories.dart`. Story entity declarations and generated parts were moved without content edits. Story submission still prevents concurrent submits and invalidates the global and returned-user story providers only on success. The native image output/compositor behavior is untouched.

## Verification

- `dart format lib/features/stories lib/features/media_editor lib/core/router/routes/social_routes.dart lib/core/router/routes/profile_routes.dart lib/core/router/routes/chat_routes.dart lib/features/social/presentation/providers/feed_provider.dart test/features/stories test/features/media_editor/image_editor_export_test.dart` — exited 0; formatted 41 files, 11 changed.
- `dart analyze lib/features/stories lib/features/media_editor` — exited 0: `No issues found!`
- Final scoped formatting was rerun after the last edits with `dart format lib/features/social/presentation/providers/feed_provider.dart lib/features/auth/presentation/controllers/auth_controller.dart lib/features/profile/presentation/pages/close_friends_page.dart lib/features/stories lib/features/media_editor test/features/stories test/features/media_editor test/features/social/feed_provider_test.dart integration_test/perf_test.dart integration_test/native_image_compositor_test.dart` — exited 0; 43 files, 1 changed.
- `git diff --check` — exited 0; Git emitted only existing LF-to-CRLF working-copy warnings. `git status --short` conflict-marker filter returned no entries.
- `flutter test --no-pub test/features/stories test/features/media_editor/image_editor_export_test.dart test/features/social/feed_provider_test.dart` — exited 1. Editor export tests reached and passed (2); story/feed tests could not compile because the shared generated localizations are stale/missing keys across the dirty integrated tree (for example `AppLocalizations.feedCreateStory`/other keys) and there are unrelated compile errors in profile, orders, dispute, and chat. Exact full output is in the orchestrator shell log; final l10n/codegen/full gates are reserved until all five owners freeze.
- `rg -n "features/social/(data/entities/story_entity|presentation/(controllers/story_submission_coordinator|pages/(create_story_page|my_stories_page|story_viewer_page|story_viewer_wrapper)|providers/story_highlight_provider|widgets/(story_canvas|story_capture_view|story_highlight_editor|story_highlights_section|story_page|story_preview_view|story_text_styles|story_thumbnail|stories_row)))|features/chat/presentation/(pages/image_editor_page|widgets/(image_editor_models|image_editor_paint|image_editor_toolbar|image_editor_views|image_editor_compositor|color_filters|draw_palette))" frontend --glob '*.dart'` — exited 1, no stale matches.

## Deferred verification / remaining owner work

- Final `build_runner`, `gen-l10n`, format/analyze/test/APK gates are intentionally not run here. The affected tests must be rerun after shared codegen and the other four workstreams freeze.
- Several visible strings in the moved story screens remain inline. Existing keys can cover some; missing English/pt-BR keys must be inventoried and added by the shared localization owner before this extraction is fully UI-localized.
- Device playback and native-pixel validation were not run in this source-only slice.

## Deviations

The patch tool rejects content-free `Move to` operations, so tracked files (including generated story parts) were moved with PowerShell `Move-Item`; generated contents were not edited. The freeze-only full gates were not run as requested.
