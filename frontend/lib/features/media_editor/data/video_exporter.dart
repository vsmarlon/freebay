import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/color_math.dart';
import '../domain/crop_geometry.dart';
import '../domain/editor_models.dart';
import '../domain/filter_presets.dart';
import 'image_exporter.dart';

class VideoExporter {
  static const MethodChannel _videoChannel = MethodChannel(
    'com.freebay.app/video_editor',
  );

  Future<File> export(
    EditorState s,
    GlobalKey overlayKey, {
    ExportQuality quality = ExportQuality.standard,
    void Function(double)? onProgress,
  }) async {
    final v = s.video;
    if (v == null) {
      throw const FormatException('State has no video configuration');
    }
    final inputPath = s.sourcePath;
    if (inputPath == null || !File(inputPath).existsSync()) {
      throw const FormatException('Video source file not found');
    }

    final tmp = await getTemporaryDirectory();
    final outPath = p.join(
      tmp.path,
      'vid_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final overlayPng = p.join(
      tmp.path,
      'ov_${DateTime.now().microsecondsSinceEpoch}.png',
    );

    // 1) Calcula dimensões esperadas
    final g = CropGeometry(s.crop, s.sourceSize);
    final crop = s.crop.rect;
    final rot = g.rotated;
    final cropWidth = crop.width * rot.width;
    final cropHeight = crop.height * rot.height;
    final rotation = s.crop.quarterTurns * 90;
    final rotatedWidth = (rotation % 180 == 0) ? cropWidth : cropHeight;
    final rotatedHeight = (rotation % 180 == 0) ? cropHeight : cropWidth;
    final maxDim = quality == ExportQuality.hd ? 1920.0 : 1280.0;
    final scale = math.min(1.0, maxDim / math.max(rotatedWidth, rotatedHeight));

    int evenDim(num val) {
      final i = val.round();
      return i.isEven ? i : i + 1;
    }

    final expectedWidth = evenDim(rotatedWidth * scale);
    final expectedHeight = evenDim(rotatedHeight * scale);

    // 2) Renderiza o overlay PNG
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        overlayKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw const FormatException('Overlay canvas not ready');
    }
    final prW = expectedWidth / boundary.size.width;
    final prH = expectedHeight / boundary.size.height;
    final pr = math.max(prW, prH).clamp(0.1, 6.0);
    final img = await boundary.toImage(pixelRatio: pr);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (byteData == null) {
      throw const FormatException('Could not render overlay PNG');
    }
    await File(overlayPng).writeAsBytes(byteData.buffer.asUint8List());

    // 3) Chama o channel nativo
    final adj = effectiveAdjustments(s);
    final matrix = adjustmentsToMatrix(adj);
    try {
      await _videoChannel.invokeMethod<void>('export', {
        'input': inputPath,
        'output': outPath,
        'overlay': overlayPng,
        'startMs': v.trimStartMs,
        'endMs': v.trimEndMs,
        'durationMs': v.durationMs,
        'crop': [crop.left, crop.top, crop.right, crop.bottom],
        'colorMatrix': matrix,
        'rotationDegrees': rotation,
        'maxDimension': maxDim.toInt(),
        'mute': v.muted,
      });
      final outFile = File(outPath);
      if (!outFile.existsSync()) {
        throw const FormatException('Video export failed or output not found');
      }
      return outFile;
    } finally {
      final f = File(overlayPng);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }
}
