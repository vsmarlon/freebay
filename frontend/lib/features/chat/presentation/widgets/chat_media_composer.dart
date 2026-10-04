import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';

Future<void> showChatMediaComposer({
  required BuildContext context,
  required Uint8List imageBytes,
  required Future<void> Function({
    required String attachmentUrl,
    required MessageType type,
    String? caption,
    required bool viewOnce,
  })
  onSend,
}) async {
  await context.push(
    AppRoutes.imageEditor,
    extra: {
      'imageBytes': imageBytes,
      'purpose': ImageEditorPurpose.chat,
      'onComplete': (ImageEditorResult result) async {
        final file = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_chat_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        try {
          await file.writeAsBytes(result.imageBytes, flush: true);
          final upload = await UploadService.uploadFile(file, 'chat');
          final url = upload.rightOrNull;
          if (url == null) {
            if (context.mounted) {
              AppSnackbar.error(
                context,
                upload.leftOrNull?.message ?? 'Erro ao enviar imagem',
              );
            }
            return false;
          }
          await onSend(
            attachmentUrl: url,
            type: MessageType.image,
            caption: result.caption,
            viewOnce: result.viewOnce,
          );
          return true;
        } finally {
          try {
            await file.delete();
          } catch (_) {}
        }
      },
    },
  );
}
