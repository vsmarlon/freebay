import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodifica a imagem com a maior borda limitada (economia de memória).
/// O `ui.Image` resultante pertence ao chamador — dispose() ao sair.
Future<ui.Image> decodeForPreview(Uint8List bytes, {int maxEdge = 2048}) async {
  if (bytes.isEmpty) throw const FormatException('Empty image');
  final descriptor = await ui.ImageDescriptor.encoded(
    await ui.ImmutableBuffer.fromUint8List(bytes),
  );
  final w = descriptor.width, h = descriptor.height;
  if (w <= 0 || h <= 0) {
    descriptor.dispose();
    throw const FormatException('Invalid image dimensions');
  }
  final scale = maxEdge / math.max(w, h);
  final codec = await descriptor.instantiateCodec(
    targetWidth: scale < 1 ? (w * scale).round() : null,
    targetHeight: scale < 1 ? (h * scale).round() : null,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  return frame.image;
}
