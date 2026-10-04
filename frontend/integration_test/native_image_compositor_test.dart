import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/features/media_editor/presentation/widgets/color_filters.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_paint.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_views.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ImageEditorPage sends the native PNG through onComplete', (
    tester,
  ) async {
    ImageEditorResult? completed;
    final source = _solidImage(64, 64, 20, 80, 160);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ImageEditorPage(
          initialImageBytes: source,
          purpose: ImageEditorPurpose.chat,
          onComplete: (result) async {
            completed = result;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('DRAW'));
    await tester.pumpAndSettle();

    final editorCanvas = tester.getRect(find.byType(EditorCanvasView));
    await tester.dragFrom(
      Offset(editorCanvas.left + 20, editorCanvas.top + 20),
      const Offset(24, 0),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.byType(EditorPreviewView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(completed, isNotNull);
    expect(_decode(completed!.imageBytes).width, 64);
    expect(_decode(completed!.imageBytes).height, 64);
  });

  testWidgets('native editor export returns correctly composited PNG pixels', (
    tester,
  ) async {
    final sourcePixels = img.Image(width: 2, height: 3, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..setPixelRgba(1, 0, 0, 255, 0, 255)
      ..setPixelRgba(0, 1, 0, 0, 255, 255)
      ..setPixelRgba(1, 1, 255, 255, 0, 255)
      ..setPixelRgba(0, 2, 255, 0, 255, 255)
      ..setPixelRgba(1, 2, 0, 255, 255, 255);
    final rotationBytes = Uint8List.fromList(img.encodePng(sourcePixels));
    final unrotated = _decode(
      await _export(rotationBytes, canvasSize: const Size(2, 3)),
    );
    expect((unrotated.width, unrotated.height), (2, 3));
    _expectRgba(unrotated.getPixel(0, 0), 255, 0, 0, 255);
    _expectRgba(unrotated.getPixel(1, 0), 0, 255, 0, 255);
    _expectRgba(unrotated.getPixel(0, 1), 0, 0, 255, 255);
    _expectRgba(unrotated.getPixel(1, 1), 255, 255, 0, 255);
    _expectRgba(unrotated.getPixel(0, 2), 255, 0, 255, 255);
    _expectRgba(unrotated.getPixel(1, 2), 0, 255, 255, 255);

    final rotatedBytes = await _export(
      rotationBytes,
      canvasSize: const Size(2, 3),
      rotation: 3.141592653589793 / 2,
    );
    final rotated = _decode(rotatedBytes);
    expect((rotated.width, rotated.height), (3, 2));
    // Clockwise quarter-turn: output(x, y) = input(y, height - 1 - x).
    _expectRgba(rotated.getPixel(0, 0), 255, 0, 255, 255);
    _expectRgba(rotated.getPixel(1, 0), 0, 0, 255, 255);
    _expectRgba(rotated.getPixel(2, 0), 255, 0, 0, 255);
    _expectRgba(rotated.getPixel(0, 1), 0, 255, 255, 255);
    _expectRgba(rotated.getPixel(1, 1), 255, 255, 0, 255);
    _expectRgba(rotated.getPixel(2, 1), 0, 255, 0, 255);
    expect(_rgbPixels(rotated), unorderedEquals(_rgbPixels(sourcePixels)));

    final counterclockwise = _decode(
      await _export(
        rotationBytes,
        canvasSize: const Size(2, 3),
        rotation: -3.141592653589793 / 2,
      ),
    );
    expect((counterclockwise.width, counterclockwise.height), (3, 2));
    _expectRgba(counterclockwise.getPixel(0, 0), 0, 255, 0, 255);
    _expectRgba(counterclockwise.getPixel(1, 0), 255, 255, 0, 255);
    _expectRgba(counterclockwise.getPixel(2, 0), 0, 255, 255, 255);
    _expectRgba(counterclockwise.getPixel(0, 1), 255, 0, 0, 255);
    _expectRgba(counterclockwise.getPixel(1, 1), 0, 0, 255, 255);
    _expectRgba(counterclockwise.getPixel(2, 1), 255, 0, 255, 255);
    expect(_rgbPixels(counterclockwise), isNot(equals(_rgbPixels(rotated))));

    final colorInput = _solidImage(2, 3, 10, 20, 30);
    final inverted = _decode(
      await _export(
        colorInput,
        canvasSize: const Size(2, 3),
        colorMatrix: const [
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ],
      ),
    );
    _expectRgb(inverted.getPixel(1, 1), 245, 235, 225);

    final canvasPixels = _decode(_solidImage(8, 8, 20, 80, 160));
    final inkAndEraser = _decode(
      await _export(
        Uint8List.fromList(img.encodePng(canvasPixels)),
        canvasSize: const Size(8, 8),
        strokes: const [
          DrawStroke(
            [Offset(1, 2.5), Offset(7, 2.5)],
            Colors.red,
            2,
            PenStyle.marker,
          ),
          DrawStroke(
            [Offset(1, 5.5), Offset(7, 5.5)],
            Colors.black,
            2,
            PenStyle.eraser,
          ),
        ],
      ),
    );
    _expectRgb(inkAndEraser.getPixel(3, 2), 255, 0, 0);
    _expectRgb(inkAndEraser.getPixel(3, 5), 20, 80, 160);

    final wideLetterbox = _decode(_solidImage(4, 2, 20, 80, 160));
    final letterboxedInk = _decode(
      await _export(
        Uint8List.fromList(img.encodePng(wideLetterbox)),
        canvasSize: const Size(8, 8),
        strokes: const [
          DrawStroke(
            [Offset(1, 3), Offset(7, 3)],
            Colors.red,
            2,
            PenStyle.marker,
          ),
        ],
      ),
    );
    _expectRgb(letterboxedInk.getPixel(2, 0), 255, 0, 0);
    expect(letterboxedInk.getPixel(2, 1).r, lessThan(100));

    final textInput = _solidImage(64, 32, 20, 80, 160);
    final withText = _decode(
      await _export(
        textInput,
        canvasSize: const Size(64, 32),
        text: const [
          TextOverlay(
            text: 'PIXEL',
            position: Offset(4, 4),
            color: Colors.white,
            fontSize: 18,
          ),
        ],
      ),
    );
    expect(
      withText.where(
        (pixel) => pixel.r > 230 && pixel.g > 230 && pixel.b > 230,
      ),
      isNotEmpty,
    );
  });
}

Future<Uint8List> _export(
  Uint8List bytes, {
  required Size canvasSize,
  double rotation = 0,
  List<double> colorMatrix = ColorFilterMatrices.normal,
  List<DrawStroke> strokes = const [],
  List<TextOverlay> text = const [],
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    try {
      final result = await exportFinalImage(
        imageBytes: bytes,
        decodedImageFuture: Future.value(frame.image),
        canvasSize: canvasSize,
        strokes: strokes,
        activePoints: null,
        color: Colors.black,
        width: 1,
        style: PenStyle.marker,
        brightness: 0,
        contrast: 1,
        saturation: 1,
        filterMatrix: colorMatrix,
        rotationAngle: rotation,
        textOverlays: text,
      );
      if (result == null) throw StateError('Native image export returned null');
      return result;
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Uint8List _solidImage(int width, int height, int r, int g, int b) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

img.Image _decode(Uint8List bytes) =>
    img.decodePng(bytes) ?? (throw StateError('Native result was not a PNG'));

List<String> _rgbPixels(img.Image image) => [
  for (final pixel in image)
    '${pixel.r.toInt()},${pixel.g.toInt()},${pixel.b.toInt()},${pixel.a.toInt()}',
];

void _expectRgb(img.Pixel pixel, int r, int g, int b) {
  expect(pixel.r, closeTo(r, 8));
  expect(pixel.g, closeTo(g, 8));
  expect(pixel.b, closeTo(b, 8));
}

void _expectRgba(img.Pixel pixel, int r, int g, int b, int a) {
  expect(pixel.r, r);
  expect(pixel.g, g);
  expect(pixel.b, b);
  expect(pixel.a, a);
}
