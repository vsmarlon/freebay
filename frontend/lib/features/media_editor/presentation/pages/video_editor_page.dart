import 'dart:io';

import 'package:flutter/material.dart';
import 'media_editor_page.dart';

/// Abre o editor de vídeo unificado (V2). Retorna o arquivo temporário editado
/// ou null se cancelado/falhou.
Future<File?> showVideoEditor(BuildContext context, File videoFile) async {
  final result = await MediaEditorPage.push(context, file: videoFile);
  return result?.file;
}

class VideoEditorPage extends StatelessWidget {
  const VideoEditorPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  Widget build(BuildContext context) {
    return MediaEditorPage(initialFile: videoFile);
  }
}
