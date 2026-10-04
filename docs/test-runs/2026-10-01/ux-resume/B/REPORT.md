# Owner B — native compositor rotation oracle

**Status:** source change prepared; Flutter execution and physical-device validation are pending. The shared Flutter/Dart SDK is reserved by executor A, so no Flutter, Dart, build, analyzer, or integration-test command was run here. No RED/GREEN result is claimed.

## Test value

1. **Observable contract:** `exportFinalImage` called on Android/iOS with a 2×3 lossless PNG and a positive quarter-turn must return a 3×2 PNG with each input RGBA pixel at its clockwise-rotated coordinate. Zero rotation preserves all six positions and channel values.
2. **Credible regression:** a compositor can return the correct dimensions and preserve the same six-color multiset while rotating counterclockwise or misplacing pixels. The prior unordered multiset assertion accepted both.
3. **Why stronger existing coverage misses it:** the integration test invoked the real export boundary, but only asserted dimensions and an unordered multiset for rotation; other native assertions cover filters, strokes/eraser, letterboxing, and text, not directional pixel coordinates.
4. **Test-only seam:** none added. The test uses the existing `exportFinalImage` adapter and the registered native method channel. The integration test is unmocked; test execution on Android and iOS remains unverified.

## Change and independent oracle

Only `frontend/integration_test/native_image_compositor_test.dart` was changed. It now checks all six exact RGBA positions in the no-rotation and clockwise outputs, retains the previous multiset assertion, and runs a genuine native counterclockwise export with its own six expected positions and verifies its pixel sequence differs from the clockwise result.

Input rows (`y=0..2`):

```text
R G
B Y
M C
```

For clockwise rotation, independently applying `(x', y') = (height - 1 - y, x)` yields output rows:

```text
M B R
C Y G
```

All source and expected pixels use alpha 255. PNG is lossless, so assertions compare exact RGBA channels, without tolerance. The counterclockwise expected rows are `G Y C` / `R B M`; this same-size inverse is the negative control demonstrating directional discrimination rather than a dimensions-only check.

## Source-only bridge confirmation

`image_editor_paint.dart` calls `composeImageNatively` for Android/iOS. `image_editor_compositor.dart` invokes method `compose` on `com.freebay.app/image_compositor`. Source registration/implementation is in `frontend/android/app/src/main/kotlin/com/freebay/app/MainActivity.kt` + `NativeImageCompositor.kt` and `frontend/ios/Runner/AppDelegate.swift` + `NativeImageCompositor.swift`. This confirms source wiring only, not execution or pixel correctness on either platform.

## Verification record

- Revision/working tree: inherited integrated working tree with extensive unrelated dirty WIP; this owner did not commit or modify other owners' files.
- Environment: Windows, FreeBay repository; shared Flutter/Dart SDK reserved by executor A.
- Commands run: none for Flutter/Dart/build/analyze/test (explicitly prohibited until parent releases SDK). No generated code or dependencies changed.
- Expected next execution: after parent releases SDK and after final root gates settle, tester runs the unmocked integration test on physical Android A30 `RX8M70JDTQV`; record exact command, exit code, and device output here. If available, run on iOS too. Android/iOS runtime evidence is pending.
- Negative control is in the test itself: real native `-π/2` export is asserted to have the independently calculated counterclockwise map and a pixel sequence unequal to the `+π/2` clockwise output, despite identical 3×2 dimensions and identical color multiset.

## Deviations / remaining limits

The canonical `.agents/skills/writing-great-tests/SKILL.md` requested by the task is absent from this checkout; `test-audit/SKILL.md` was read and its four-part test-value gate is recorded above. No substitute skill was invented. Runtime validation is pending rather than simulated because no SDK command was permitted and no device run occurred.
