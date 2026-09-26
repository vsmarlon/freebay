import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freebay/features/chat/presentation/pages/location_picker_page.dart';
import 'package:freebay/features/chat/presentation/widgets/attachment_bottom_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_video_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/make_offer_dialog.dart';
import 'package:freebay/features/chat/presentation/widgets/product_picker_sheet.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';

/// Attachment sheet wiring for the conversation page.
///
/// All server writes go through [sendRich]/[sendLocation]; this flow only
/// shows sheets, composers and dialogs and forwards their results.
Future<void> showConversationAttachmentSheet({
  required BuildContext context,
  required String? Function() takeReplyTarget,
  required Future<void> Function({
    required MessageType type,
    String? content,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce,
  })
  sendRich,
  required Future<void> Function({
    required Map<String, dynamic> metadata,
    required String? replyToId,
    required String clientMessageId,
  })
  sendLocation,
  required void Function(String message) showError,
}) {
  return showAttachmentSheet(
    context: context,
    onMediaReady: (attachment) async {
      final replyId = takeReplyTarget();
      await sendRich(
        type: attachment.type,
        attachmentUrl: attachment.url,
        replyToId: replyId,
      );
    },
    returnRawFile: true,
    onRawImage: (xfile) async {
      final bytes = await xfile.readAsBytes();
      if (!context.mounted) return;
      await showChatMediaComposer(
        context: context,
        imageBytes: bytes,
        onSend:
            ({
              required attachmentUrl,
              required type,
              caption,
              required viewOnce,
            }) async {
              final replyId = takeReplyTarget();
              await sendRich(
                type: type,
                content: caption,
                attachmentUrl: attachmentUrl,
                replyToId: replyId,
                viewOnce: viewOnce,
              );
            },
      );
    },
    onRawVideo: (xfile) => showChatVideoComposer(
      context: context,
      videoFile: File(xfile.path),
      onSend:
          ({
            required attachmentUrl,
            required type,
            caption,
            required viewOnce,
          }) async {
            final replyId = takeReplyTarget();
            await sendRich(
              type: type,
              content: caption,
              attachmentUrl: attachmentUrl,
              replyToId: replyId,
              viewOnce: viewOnce,
            );
          },
    ),
    onLocationTap: () async {
      final loc = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const LocationPickerPage()),
      );
      if (loc != null && context.mounted) {
        final replyId = takeReplyTarget();
        await sendLocation(
          metadata: loc,
          replyToId: replyId,
          clientMessageId: 'location-${DateTime.now().microsecondsSinceEpoch}',
        );
      }
    },
    onProductTap: () => showProductPickerSheet(
      context: context,
      onProductSelected: (meta) async {
        final replyId = takeReplyTarget();
        await sendRich(
          type: MessageType.productCard,
          replyToId: replyId,
          metadata: meta,
        );
      },
    ),
    onOfferTap: () => showDialog(
      context: context,
      builder: (_) => MakeOfferDialog(
        onSendOffer: (offerData) async {
          final replyId = takeReplyTarget();
          await sendRich(
            type: MessageType.unknown,
            replyToId: replyId,
            metadata: offerData,
          );
        },
      ),
    ),
    onError: showError,
  );
}
