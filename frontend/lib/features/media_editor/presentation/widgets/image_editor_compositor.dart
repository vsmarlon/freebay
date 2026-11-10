import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_models.dart';

const _channel = MethodChannel('com.freebay.app/image_compositor');
// ponytail: 2048px bounds primary mobile RGBA working buffers to about 64 MiB.
const _maxDimension = 2048;
const _maxEncodedBytes = 32 * 1024 * 1024;
const _maxStrokePoints = 200000;

Future<Uint8List> composeImageNatively({
  required Uint8List imageBytes,
  required int imageWidth,
  required int imageHeight,
  required Size canvasSize,
  required List<DrawStroke> strokes,
  required List<Offset>? activePoints,
  required Color color,
  required double width,
  required PenStyle style,
  required List<double> filterMatrix,
  required double rotationAngle,
  required List<TextOverlay> textOverlays,
}) async {
  if (imageBytes.isEmpty ||
      imageBytes.length > _maxEncodedBytes ||
      imageWidth <= 0 ||
      imageHeight <= 0 ||
      imageWidth > 100000 ||
      imageHeight > 100000 ||
      canvasSize.width <= 0 ||
      !canvasSize.width.isFinite ||
      canvasSize.height <= 0 ||
      !canvasSize.height.isFinite ||
      !rotationAngle.isFinite ||
      filterMatrix.length != 20 ||
      filterMatrix.any((value) => !value.isFinite)) {
    throw const FormatException('Invalid image composition input');
  }
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    throw UnsupportedError('Native image compositor is mobile-only');
  }

  final allStrokes = <DrawStroke>[
    ...strokes,
    if (activePoints != null && activePoints.isNotEmpty)
      DrawStroke(activePoints, color, width, style),
  ];
  final strokePayload = <Map<String, Object?>>[];
  var totalPoints = 0;
  for (final stroke in allStrokes) {
    totalPoints += stroke.points.length;
    if (!stroke.width.isFinite ||
        stroke.width <= 0 ||
        stroke.width > 1000 ||
        stroke.points.length > 10000 ||
        totalPoints > _maxStrokePoints) {
      throw const FormatException('Invalid image stroke');
    }
    strokePayload.add({
      'points': stroke.points
          .map((point) => <double>[point.dx, point.dy])
          .toList(growable: false),
      'argb': stroke.color.toARGB32(),
      'width': stroke.width,
      'style': stroke.style.name,
    });
  }
  final textPayload = textOverlays
      .map((overlay) {
        if (overlay.text.length > 2000 ||
            !overlay.position.dx.isFinite ||
            !overlay.position.dy.isFinite ||
            !overlay.fontSize.isFinite ||
            overlay.fontSize <= 0 ||
            overlay.fontSize > 4096) {
          throw const FormatException('Invalid image text overlay');
        }
        return <String, Object?>{
          'text': overlay.text,
          'x': overlay.position.dx,
          'y': overlay.position.dy,
          'argb': overlay.color.toARGB32(),
          'fontSize': overlay.fontSize,
        };
      })
      .toList(growable: false);

  final output = await _channel.invokeMethod<Uint8List>('compose', {
    'bytes': imageBytes,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'canvasWidth': canvasSize.width,
    'canvasHeight': canvasSize.height,
    'rotationRadians': rotationAngle,
    'colorMatrix': filterMatrix,
    'strokes': strokePayload,
    'text': textPayload,
    'maxDimension': _maxDimension,
  });
  if (output == null || output.isEmpty) {
    throw PlatformException(code: 'empty_result');
  }
  return output;
}
