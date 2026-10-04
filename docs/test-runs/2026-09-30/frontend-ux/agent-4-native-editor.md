# Native image editor compositor — executor 4

Date: 2026-09-30  
Base revision: `455818164b7b87e5d57eb1dd84313eacd9ce580b`  
Working tree: shared multi-agent checkout; no commit created.

## Implementation

- Mobile export now calls `com.freebay.app/image_compositor` with the cropped/original image bytes, preview dimensions, 20-value color matrix, strokes (including any active stroke), and text overlays. Android and iOS return flattened PNG bytes; those bytes continue through the existing `ImageEditorResult` chat/post/story upload callers.
- Android decodes and applies EXIF orientation, filters the image pixels, composites paths/text, and returns PNG off the UI thread. The eraser clears only the transparent drawing layer, leaving image pixels intact. It loads the declared `SpaceGrotesk[wght].ttf` from Flutter assets, with platform sans-serif only as a missing-asset fallback.
- iOS uses ImageIO downsampling with EXIF transform, Core Image color-matrix processing, Core Graphics strokes and text, and returns PNG off the UI thread. It registers the declared font from `App.framework/flutter_assets/assets/fonts/SpaceGrotesk[wght].ttf`; system bold is the fallback when the asset/name is unavailable. `AppDelegate` retains generated plugin registration and registers the handler on the implicit engine; the Swift file is included in Runner sources.
- The editor retains edits and stays on the editing step on native composition failure. Non-mobile targets retain the existing Flutter renderer.
- Output is limited to 2048px per dimension and encoded input to 32 MiB; aggregate stroke points are capped at 200,000 with an explicit composition error rather than silently truncated. Android recycles decoded, orientation-adjusted, overlay, and output bitmaps in `finally`. The four principal iOS RGBA working buffers are approximately 64 MiB at the pixel cap.
- An editor-local compositing guard prevents repeated confirmation taps from launching overlapping exports and multiplying those working buffers.

## Behavioral evidence

Before native implementation, `flutter test test/features/chat/image_editor_export_test.dart` exercised the existing exporter and verified a visible stroke was flattened into PNG pixels (1 test passed). The test also covers the native MethodChannel argument payload; the mocked channel validates Dart serialization, not native pixel output.

After implementation:

- `flutter test test/features/chat/image_editor_export_test.dart` — 2 tests passed; exit 0.
- Scoped `flutter analyze --fatal-infos ...image_editor...` — no issues; exit 0.
- Scoped `dart format --output=none --set-exit-if-changed ...image_editor...` — unchanged; exit 0.
- `.\gradlew.bat :app:compileDebugKotlin -x :app:compileFlutterBuildDebug` from `frontend/android` — BUILD SUCCESSFUL; exit 0. The command skipped Flutter compilation/localization generation.

## Real-device test prepared; execution pending final verification window

`frontend/integration_test/native_image_compositor_test.dart` uses Flutter's `IntegrationTestWidgetsFlutterBinding` and the production `exportFinalImage` path. It does not install a MethodChannel mock. It checks rotation output bounds and every fixture pixel, matrix-filtered colors, ink and eraser transparency while preserving base pixels, contain-fit letterbox coordinates, visible text pixels, and the real `ImageEditorPage` `onComplete` callback returning PNG bytes.

Run on a connected Android or iOS device after the shared working tree is frozen:

```bash
flutter test integration_test/native_image_compositor_test.dart -d <device-id>
```

The integration test is prepared but has not been executed. Existing production callers were traced: chat writes `ImageEditorResult.imageBytes` as PNG and uploads it; post and story write the same bytes to their selected image file for existing upload paths. The integration journey reaches the editor callback; backend upload journeys still require the final device/backend fixture wave.

Continuation note: native resource cleanup, input caps, editor export serialization, and the unmocked integration test were added after the earlier scoped checks above. Per owner instruction, no test, analyzer, Gradle build, codegen, or device run was started for these continuation changes. Validate them in the coordinated final verification window.

## Full-gate results and limits

- `dart run build_runner build --delete-conflicting-outputs` — blocked by a parse error at `frontend/lib/features/social/presentation/providers/likes_provider.dart:103`; that file belongs to another active working-tree change. Build runner removed its generated `.g.dart` because that source currently has no `part` directive; this side effect is outside this task's ownership and was left for its owner to resolve.
- `flutter analyze --fatal-infos lib test libs/freebay_design_system/lib` — blocked by existing shared-tree errors in product caching, review image imports, social likes, generated localizations, and a deletion test override; see command output. The changed image-editor files analyzed cleanly.
- `flutter test` — blocked by compilation errors in the same shared-tree product/review/social files; unrelated runnable cases began, but the suite did not pass.
- Full Dart format gate — exited nonzero because the shared tree contains the malformed social likes source. Formatter reported changes across files outside this executor's scope; the editor files are formatted. Concurrent owner should inspect those formatter changes before landing.
- `flutter build apk --debug` — blocked before app compilation: the existing `frontend/l10n.yaml` requires generated localization output, but `frontend/pubspec.yaml` lacks `flutter: generate: true`. The app build configuration is outside this executor's ownership.
- iOS compilation was not available from this Windows verification session. Run the prepared real-channel integration test on Android and iOS devices; it covers rotation bounds, filters, ink/eraser pixel retention, letterbox mapping, text pixels, and editor callback bytes. EXIF fixture behavior and end-to-end upload should be included when the final device/backend fixtures are available.

No device or provider evidence is claimed.
