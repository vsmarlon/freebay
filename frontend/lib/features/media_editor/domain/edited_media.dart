import 'dart:io';

import 'editor_models.dart';

/// Contrato de resultado entregue ao chamador (guia seção 4).
class EditedMedia {
  const EditedMedia({
    required this.file,
    required this.kind,
    required this.width,
    required this.height,
    this.durationMs,
    this.thumbnail,
    this.caption = '',
    this.hd = false,
    this.viewOnce = false,
    this.altText,
  });

  final File file;
  final MediaKind kind;
  final int width;
  final int height;
  final int? durationMs;

  /// Capa do vídeo ou thumb da imagem
  final File? thumbnail;
  final String caption;
  final bool hd;
  final bool viewOnce;
  final String? altText;
}
