import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/features/chat/presentation/widgets/video_message_bubble.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

Future<void> showChatVideoComposer({
  required BuildContext context,
  required File videoFile,
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
}) {
  return showBrutalistSheet<void>(
    context: context,
    title: l10n(context).chatVideoSend,
    builder: (_) => _ChatVideoComposer(
      videoFile: videoFile,
      onSend: onSend,
      initialViewOnce: initialViewOnce,
      initialCaption: initialCaption,
    ),
  );
}

class _ChatVideoComposer extends StatefulWidget {
  final File videoFile;
  final bool initialViewOnce;
  final String? initialCaption;
  final Future<bool> Function({
    required String attachmentUrl,
    required MessageType type,
    String? caption,
    required bool viewOnce,
    CancelToken? cancelToken,
  })
  onSend;

  const _ChatVideoComposer({
    required this.videoFile,
    required this.onSend,
    required this.initialViewOnce,
    required this.initialCaption,
  });

  @override
  State<_ChatVideoComposer> createState() => _ChatVideoComposerState();
}

class _ChatVideoComposerState extends State<_ChatVideoComposer> {
  final _captionController = TextEditingController();
  late bool _viewOnce = widget.initialViewOnce;
  bool _isBusy = false;
  bool _slow = false;
  CancelToken? _cancelToken;
  Timer? _slowTimer;
  File? _editedVideoFile;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption ?? '';
  }

  @override
  void dispose() {
    _captionController.dispose();
    _slowTimer?.cancel();
    _cancelToken?.cancel('Composer closed');
    final edited = _editedVideoFile;
    if (edited != null) unawaited(edited.delete().catchError((_) => edited));
    super.dispose();
  }

  Future<void> _editVideo() async {
    final edited = await showVideoEditor(
      context,
      _editedVideoFile ?? widget.videoFile,
    );
    if (!mounted || edited == null) return;
    final previous = _editedVideoFile;
    setState(() => _editedVideoFile = edited);
    if (previous != null && previous.path != edited.path) {
      await previous.delete().catchError((_) => previous);
    }
  }

  Future<void> _send() async {
    if (_isBusy) return;
    final strings = l10n(context);
    final cancelToken = CancelToken();
    _slowTimer?.cancel();
    _cancelToken = cancelToken;
    setState(() {
      _isBusy = true;
      _slow = false;
    });
    _slowTimer = Timer(const Duration(seconds: 15), () {
      if (mounted &&
          !cancelToken.isCancelled &&
          identical(_cancelToken, cancelToken)) {
        setState(() => _slow = true);
      }
    });

    try {
      final result = await UploadService.uploadFile(
        _editedVideoFile ?? widget.videoFile,
        'chat',
        cancelToken: cancelToken,
      );
      if (!mounted || cancelToken.isCancelled) return;
      final url = result.rightOrNull;
      if (url == null) {
        if (mounted) {
          AppSnackbar.error(
            context,
            result.leftOrNull?.message ?? strings.chatSendFailed,
          );
        }
        return;
      }

      final caption = _captionController.text.trim();
      final sent = await widget.onSend(
        attachmentUrl: url,
        type: MessageType.video,
        caption: caption.isEmpty ? null : caption,
        viewOnce: _viewOnce,
        cancelToken: cancelToken,
      );
      if (sent && mounted && !cancelToken.isCancelled) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted && !cancelToken.isCancelled) {
        AppSnackbar.error(context, strings.chatSendFailed);
      }
    } finally {
      if (identical(_cancelToken, cancelToken)) {
        _slowTimer?.cancel();
        _slowTimer = null;
        _cancelToken = null;
        if (mounted) {
          setState(() {
            _isBusy = false;
            _slow = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: VideoMessageBubble(
            videoUrl: null,
            isMe: true,
            localFilePath: (_editedVideoFile ?? widget.videoFile).path,
            autoPlay: true,
          ),
        ),
        AppButton(
          label: strings.commonEdit,
          variant: AppButtonVariant.secondary,
          onPressed: _isBusy ? null : _editVideo,
          icon: Icons.edit,
        ),
        if (_slow)
          Row(
            children: [
              Expanded(child: Text(strings.chatSendingSlow)),
              AppButton(
                variant: AppButtonVariant.secondary,
                label: strings.commonCancel,
                onPressed: () {
                  final token = _cancelToken;
                  if (token == null) return;
                  token.cancel('Cancelled by user');
                  _slowTimer?.cancel();
                  _slowTimer = null;
                  _cancelToken = null;
                  setState(() {
                    _isBusy = false;
                    _slow = false;
                  });
                  AppSnackbar.info(context, strings.chatSendCancelled);
                },
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            ViewOnceToggle(
              enabled: _viewOnce,
              semanticLabel: strings.chatViewOnce,
              onTap: () => setState(() => _viewOnce = !_viewOnce),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _captionController,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMedium.copyWith(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: strings.chatVideoCaption,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: context.textSecondary,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.borderColor, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primaryContainer,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: strings.chatSendText,
          isLoading: _isBusy,
          onPressed: _isBusy ? null : _send,
          width: double.infinity,
          icon: Icons.send,
        ),
      ],
    );
  }
}
