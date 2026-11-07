import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../application/editor_config.dart';
import '../widgets/image_editor_models.dart';
import 'media_editor_page.dart';

/// Ponto de entrada legado para edição de imagem, agora redirecionando
/// para o motor unificado V2 MediaEditorPage com paridade WhatsApp/Instagram.
class ImageEditorPage extends StatelessWidget {
  final Uint8List initialImageBytes;
  final ImageEditorPurpose purpose;
  final bool initialViewOnce;
  final Future<bool> Function(ImageEditorResult result) onComplete;

  const ImageEditorPage({
    super.key,
    required this.initialImageBytes,
    required this.purpose,
    this.initialViewOnce = false,
    required this.onComplete,
  });

  EditorConfig _configFor(ImageEditorPurpose purpose) {
    return switch (purpose) {
      ImageEditorPurpose.chat => EditorConfig.chat,
      ImageEditorPurpose.post => EditorConfig.post,
      ImageEditorPurpose.story => EditorConfig.story,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MediaEditorPage(
      initialImageBytes: initialImageBytes,
      purpose: purpose,
      config: _configFor(purpose),
      initialViewOnce: initialViewOnce,
      onComplete: onComplete,
    );
  }
}
