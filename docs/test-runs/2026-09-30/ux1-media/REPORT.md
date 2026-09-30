# UX media focused verification

Date: 2026-09-30  
Worktree: `C:/Users/Qiyana/AppData/Local/Temp/opencode/freebay-ux-media`  
Base/HEAD at start: `4558181` / `9b52568` (`fix: improve chat video and story playback`).  
No device run was performed. Tests use a widget harness and a fake `VideoPlayerPlatform` only at the video-player plugin boundary.

## Red/green evidence

| Regression | RED on temporarily reverted behavior | GREEN after the focused fix |
|---|---|---|
| Story hold pauses immediately with a decoded story image | `flutter test test/features/social/story_viewer_interaction_test.dart` failed at line 53: `Expected: false / Actual: <true>` for `animationController.isAnimating` immediately after pointer-down. This intentionally disabled the pointer-down pause callback. | Included in the focused suite below: passed. The test primes two distinct decoded 1×1 PNG `ui.Image`s under the exact `ResizeImage(NetworkImage(...), width: physicalWidth.clamp(1, 1440))` cache keys; it makes no network request and has no production test hook. It checks immediate pause, persistence through a nine-second hold, resume on up, and eventual advancement after the remaining photo duration. |
| Chat preview tap opens fullscreen and hands over its paused player | The initial focused widget test found no `VideoViewerControls` after tapping the video surface. Root cause: `GestureDetector` used its default defer-to-child hit testing around the platform video view. | Included in the focused suite below: passed. The surface now uses opaque hit testing, and the initialized paused controller is transferred into the shared viewer (the assertion verifies no second platform-player creation). |
| Fullscreen scrubber has accessible slider semantics | With only the `Semantics` wrapper around `VideoProgressIndicator` temporarily removed, the focused viewer test failed at line 73: `Expected: exactly one matching candidate / Actual: ... 0 widgets with a semantics label named "Posição do vídeo"`. | Included in the focused suite below: passed. The same test checks the changing elapsed/total display, play/pause, mute/unmute, scrubbing/seek, and end/replay labels. |

The previous sheet regression remains in the run: its old Cupertino route failed the drag-to-dismiss assertion; the Material bottom-sheet route passed it.

## Final focused commands

Temporary build prerequisite: `frontend/pubspec.yaml` declares `.env` as an asset, but this isolated worktree did not contain the ignored file. For local verification only, a temporary `.env` containing `API_BASE_URL=http://localhost:3000` was present; it is not committed and is removed after this run.

1. `dart format lib/core/components/app_video_viewer.dart lib/core/components/app_video_viewer/video_source_resolver.dart lib/core/components/app_video_viewer/video_viewer_controls.dart lib/features/chat/presentation/widgets/video_message_bubble.dart lib/features/social/presentation/pages/story_viewer_page.dart lib/features/social/presentation/widgets/story_page.dart libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart test/core/components/app_video_viewer_test.dart test/features/social/story_viewer_interaction_test.dart test/design_system/brutalist_bottom_sheet_test.dart`
   - Exit 0; `Formatted 10 files (2 changed)`.
2. `flutter test test/core/components/app_video_viewer_test.dart test/features/social/story_viewer_interaction_test.dart test/design_system/brutalist_bottom_sheet_test.dart`
   - Exit 0; `00:01 +5: All tests passed!` (three video tests, one story test, one sheet test).
3. `flutter analyze lib/core/components/app_video_viewer.dart lib/core/components/app_video_viewer/video_source_resolver.dart lib/core/components/app_video_viewer/video_viewer_controls.dart lib/features/chat/presentation/widgets/video_message_bubble.dart lib/features/social/presentation/pages/story_viewer_page.dart lib/features/social/presentation/widgets/story_page.dart libs/freebay_design_system/lib/components/brutalist_bottom_sheet.dart`
   - Exit 0; `No issues found! (ran in 4.7s)`.

The focused test source imports the already-resolved `video_player_platform_interface` (version 6.9.0) to fake the video plugin boundary. No package version was installed or upgraded. `flutter analyze` on that test file itself reports the single info `depend_on_referenced_packages` because the SDK interface is transitive in `pubspec.yaml`; no ignore directive or pubspec/lockfile change was added per the no-new-dependency constraint. The production analyzer command above is clean.

## Scope / limits

- View-once authorization was not reimplemented; the existing message-bubble reveal gate still owns whether `VideoMessageBubble` is built.
- The new preview test covers the no-thumbnail paused-frame path and fullscreen handoff. It does not exercise authenticated thumbnail HTTP delivery or actual native decoder playback.
- Fullscreen retry is exercised from the real viewer error state with an invalid `file:` URI; tapping re-enters the resolver path and leaves the retry action available for another attempt. This does not prove successful recovery from an HTTP outage. No device-level network retry or real decoder/provider test was run.
- Tests are widget/plugin-boundary evidence, not a device verification claim.
