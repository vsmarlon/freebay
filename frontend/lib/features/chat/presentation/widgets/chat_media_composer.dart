import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';

Future<void> showChatMediaComposer({
  required BuildContext context,
  required Uint8List imageBytes,
  bool initialViewOnce = false,
  String? initialCaption,
  required Future<bool> Function({
    required String attachmentUrl,
    required MessageType type,
    String? caption,
    required bool viewOnce,
    CancelToken? cancelToken,
  })
  onSend,
}) async {
  CancelToken? activeToken;
  try {
    final request = ImageEditorRouteRequest(
      imageBytes: imageBytes,
      purpose: ImageEditorPurpose.chat,
      initialViewOnce: initialViewOnce,
      onComplete: (ImageEditorResult result) async {
        final file = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_chat_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        final cancelToken = CancelToken();
        activeToken = cancelToken;
        Timer? slowTimer;
        try {
          await file.writeAsBytes(result.imageBytes, flush: true);
          slowTimer = Timer(const Duration(seconds: 15), () {
            if (!context.mounted || cancelToken.isCancelled) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n(context).chatSendingSlow),
                action: SnackBarAction(
                  label: l10n(context).commonCancel,
                  onPressed: () {
                    cancelToken.cancel('Cancelled by user');
                    AppSnackbar.info(context, l10n(context).chatSendCancelled);
                  },
                ),
              ),
            );
          });
          final upload = await UploadService.uploadFile(
            file,
            'chat',
            cancelToken: cancelToken,
          );
          if (!context.mounted || cancelToken.isCancelled) return false;
          final url = upload.rightOrNull;
          if (url == null) {
            if (context.mounted) {
              AppSnackbar.error(context, l10n(context).errorUploadFailed);
            }
            return false;
          }
          final sent = await onSend(
            attachmentUrl: url,
            type: MessageType.image,
            caption: result.caption ?? initialCaption,
            viewOnce: result.viewOnce,
            cancelToken: cancelToken,
          );
          return sent;
        } finally {
          slowTimer?.cancel();
          try {
            await file.delete();
          } catch (_) {}
        }
      },
    );
    await request.push<void>(context, AppRoutes.imageEditor);
  } finally {
    activeToken?.cancel('Image composer closed');
  }
}
