import 'dart:io';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/features/chat/presentation/pages/location_picker_page.dart';
import 'package:freebay/features/chat/presentation/widgets/attachment_bottom_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_video_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/make_offer_dialog.dart';
import 'package:freebay/features/chat/presentation/widgets/product_picker_sheet.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Attachment sheet wiring for the conversation page.
///
/// All server writes go through [sendRich]/[sendLocation]; this flow only
/// shows sheets, composers and dialogs and forwards their results.
Future<void> showConversationAttachmentSheet({
  required BuildContext context,
  bool openCamera = false,
  bool initialViewOnce = false,
  String? initialCaption,
  VoidCallback? onAttachmentSent,
  required String? Function() takeReplyTarget,
  required Future<bool> Function({
    required MessageType type,
    String? content,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce,
    CancelToken? cancelToken,
  })
  sendRich,
  required Future<void> Function({
    required Map<String, dynamic> metadata,
    required String? replyToId,
    required String clientMessageId,
  })
  sendLocation,
  required void Function(String message) showError,
}) async {
  Future<void> composeImage(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    if (!context.mounted) return;
    await showChatMediaComposer(
      context: context,
      imageBytes: bytes,
      initialViewOnce: initialViewOnce,
      initialCaption: initialCaption,
      onSend:
          ({
            required attachmentUrl,
            required type,
            caption,
            required viewOnce,
            cancelToken,
          }) async {
            final replyId = takeReplyTarget();
            final attachmentCaption = (caption ?? initialCaption)?.trim();
            final sent = await sendRich(
              type: type,
              content: attachmentCaption == null || attachmentCaption.isEmpty
                  ? null
                  : attachmentCaption,
              attachmentUrl: attachmentUrl,
              replyToId: replyId,
              viewOnce: viewOnce,
              cancelToken: cancelToken,
            );
            if (sent) onAttachmentSent?.call();
            return sent;
          },
    );
  }

  if (openCamera) {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (photo != null && context.mounted) await composeImage(photo);
    } catch (_) {
      if (context.mounted) showError(l10n(context).feedCameraUnavailable);
    }
    return;
  }

  return showAttachmentSheet(
    context: context,
    onMediaReady: (attachment) async {
      final replyId = takeReplyTarget();
      final caption = initialCaption?.trim();
      final sent = await sendRich(
        type: attachment.type,
        content: caption == null || caption.isEmpty ? null : caption,
        attachmentUrl: attachment.url,
        replyToId: replyId,
      );
      if (sent) onAttachmentSent?.call();
    },
    returnRawFile: true,
    onRawImage: composeImage,
    onRawVideo: (xfile) => showChatVideoComposer(
      context: context,
      videoFile: File(xfile.path),
      initialViewOnce: initialViewOnce,
      initialCaption: initialCaption,
      onSend:
          ({
            required attachmentUrl,
            required type,
            caption,
            required viewOnce,
            cancelToken,
          }) async {
            final replyId = takeReplyTarget();
            final attachmentCaption = (caption ?? initialCaption)?.trim();
            final sent = await sendRich(
              type: type,
              content: attachmentCaption == null || attachmentCaption.isEmpty
                  ? null
                  : attachmentCaption,
              attachmentUrl: attachmentUrl,
              replyToId: replyId,
              viewOnce: viewOnce,
              cancelToken: cancelToken,
            );
            if (sent) onAttachmentSent?.call();
            return sent;
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
          // ponytail: backend has no OFFER MessageType, so offers ride a
          // TEXT envelope; MessageEntity.fromJson normalizes them back to
          // offers from the metadata. content keeps the chat-list preview
          // from rendering an empty last-message line.
          await sendRich(
            type: MessageType.text,
            content: l10n(context).chatOfferPreview(
              CurrencyUtils.formatCents(offerData['offerPrice'] as int? ?? 0),
            ),
            replyToId: replyId,
            metadata: offerData,
          );
        },
      ),
    ),
    onError: showError,
  );
}
