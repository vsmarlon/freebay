import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum ExportQuality { standard, hd }

/// Pipeline único de export: o que aparece no preview é o que sai
/// (RepaintBoundary → PNG → JPEG nativo, sem EXIF/GPS).
class ImageExporter {
  /// Captura o canvas em [exportKey] e salva em arquivo JPEG temporário.
  Future<File> export(
    GlobalKey exportKey, {
    ExportQuality quality = ExportQuality.standard,
    double? previewLongest,
  }) async {
    final bytes = await exportJpeg(
      exportKey,
      previewLongest:
          previewLongest ?? (quality == ExportQuality.hd ? 4096.0 : 2048.0),
      targetLongEdge: quality == ExportQuality.hd ? 4096 : 1600,
      jpegQuality: quality == ExportQuality.hd ? 92 : 82,
    );
    final dir = await getTemporaryDirectory();
    final out = File(
      p.join(dir.path, 'edit_${DateTime.now().microsecondsSinceEpoch}.jpg'),
    );
    await out.writeAsBytes(bytes);
    return out;
  }

  /// Captura o canvas em [exportKey] e comprime para bytes JPEG.
  ///
  /// [previewLongest] = maior borda da imagem decodificada para preview —
  /// o export nunca faz upscale além dela. Chame `controller.select(null)`
  /// antes para esconder a borda de seleção.
  Future<Uint8List> exportJpeg(
    GlobalKey exportKey, {
    required double previewLongest,
    int targetLongEdge = 1600,
    int jpegQuality = 82,
  }) async {
    final boundary =
        exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw const FormatException('Editor canvas not available');
    }
    await WidgetsBinding.instance.endOfFrame;
    final longest = boundary.size.longestSide;
    if (longest <= 0) throw const FormatException('Editor canvas has no size');
    var pixelRatio = math.min(
      targetLongEdge / longest,
      previewLongest / longest,
    );
    pixelRatio = pixelRatio.clamp(1.0, 6.0);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw const FormatException('Could not capture editor canvas');
    }
    final jpeg = await FlutterImageCompress.compressWithList(
      data.buffer.asUint8List(),
      quality: jpegQuality,
      // ponytail: min width/height 1 = sem resize nativo; o tamanho já é o
      // do canvas capturado (pixelRatio acima).
      minWidth: 1,
      minHeight: 1,
    );
    if (jpeg.isEmpty) {
      throw const FormatException('JPEG compression produced no data');
    }
    return jpeg;
  }
}
