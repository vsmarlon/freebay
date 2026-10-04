import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_models.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_paint.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_compositor.dart';
import 'package:freebay/features/media_editor/presentation/widgets/color_filters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export flattens a drawn stroke into PNG pixels', () async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.transparent, BlendMode.src);
    final source = await recorder.endRecording().toImage(8, 8);
    final sourceData = await source.toByteData(format: ui.ImageByteFormat.png);
    final sourceBytes = Uint8List.fromList(sourceData!.buffer.asUint8List());
    source.dispose();

    final encoded = await exportFinalImage(
      imageBytes: sourceBytes,
      decodedImageFuture: ui.instantiateImageCodec(sourceBytes).then((
        codec,
      ) async {
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      }),
      canvasSize: const Size(8, 8),
      strokes: const [
        DrawStroke(
          [Offset(1, 4), Offset(6, 4)],
          Colors.red,
          2,
          PenStyle.marker,
        ),
      ],
      activePoints: null,
      color: Colors.red,
      width: 2,
      style: PenStyle.marker,
      brightness: 0,
      contrast: 1,
      saturation: 1,
      filterMatrix: ColorFilterMatrices.normal,
      rotationAngle: 0,
      textOverlays: const [],
    );

    expect(encoded, isNotNull);
    final codec = await ui.instantiateImageCodec(encoded!);
    final result = await codec.getNextFrame();
    final pixels = await result.image.toByteData();
    final pixelOffset = (4 * 8 + 3) * 4;
    expect(pixels!.getUint8(pixelOffset), greaterThan(200));
    expect(pixels.getUint8(pixelOffset + 3), greaterThan(200));
    result.image.dispose();
    codec.dispose();
  });

  test(
    'native compositor receives source pixels and editor operations',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final channel = const MethodChannel('com.freebay.app/image_compositor');
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      Map<Object?, Object?>? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'compose');
        received = call.arguments! as Map<Object?, Object?>;
        return Uint8List.fromList([137, 80, 78, 71]);
      });
      try {
        final original = Uint8List.fromList([1, 2, 3]);
        final output = await composeImageNatively(
          imageBytes: original,
          imageWidth: 8,
          imageHeight: 8,
          canvasSize: const Size(100, 100),
          strokes: const [
            DrawStroke([Offset(10, 20)], Colors.red, 4, PenStyle.marker),
          ],
          activePoints: null,
          color: Colors.blue,
          width: 3,
          style: PenStyle.highlighter,
          filterMatrix: ColorFilterMatrices.normal,
          rotationAngle: 0,
          textOverlays: const [
            TextOverlay(
              text: 'Hi',
              position: Offset(2, 3),
              color: Colors.white,
              fontSize: 12,
            ),
          ],
        );
        expect(output, [137, 80, 78, 71]);
        expect(received?['bytes'], original);
        expect(received?['imageWidth'], 8);
        expect((received?['strokes'] as List).length, 1);
        expect((received?['text'] as List).length, 1);
        expect(received?['maxDimension'], 2048);
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    },
  );
}
