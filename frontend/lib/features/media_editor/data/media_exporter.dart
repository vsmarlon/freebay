import 'package:flutter/material.dart';

import '../application/editor_controller.dart';
import '../domain/edited_media.dart';
import '../domain/editor_models.dart';
import 'image_exporter.dart';
import 'video_exporter.dart';

class MediaExporter {
  Future<EditedMedia> run(
    EditorState s, {
    required GlobalKey exportKey,
    required GlobalKey overlayKey,
    required EditorController ctrl,
    void Function(double)? onProgress,
  }) async {
    ctrl.select(null); // Desmarca qualquer camada antes da captura
    await WidgetsBinding.instance.endOfFrame;

    final q = s.hd ? ExportQuality.hd : ExportQuality.standard;
    if (s.kind == MediaKind.image) {
      final f = await ImageExporter().export(
        exportKey,
        quality: q,
        // nunca faz upscale além da resolução decodificada (guia seção 13).
        previewLongest: s.sourceSize.longestSide,
      );
      return EditedMedia(
        file: f,
        kind: MediaKind.image,
        width: s.sourceSize.width.toInt(),
        height: s.sourceSize.height.toInt(),
        thumbnail: f,
        caption: s.caption,
        hd: s.hd,
        viewOnce: s.viewOnce,
        altText: s.altText,
      );
    }
    final f = await VideoExporter().export(
      s,
      overlayKey,
      quality: q,
      onProgress: onProgress,
    );
    return EditedMedia(
      file: f,
      kind: MediaKind.video,
      width: s.sourceSize.width.toInt(),
      height: s.sourceSize.height.toInt(),
      durationMs: s.video != null
          ? (s.video!.trimmedMs / s.video!.speed).round()
          : null,
      caption: s.caption,
      hd: s.hd,
      viewOnce: s.viewOnce,
      altText: s.altText,
    );
  }
}
