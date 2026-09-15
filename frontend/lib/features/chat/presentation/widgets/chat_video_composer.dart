import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:video_player/video_player.dart';

Future<void> showChatVideoComposer({
  required BuildContext context,
  required File videoFile,
  required Future<void> Function({
    required String attachmentUrl,
    required String type,
    String? caption,
    required bool viewOnce,
  })
  onSend,
}) {
  return showBrutalistSheet<void>(
    context: context,
    title: 'ENVIAR VÍDEO',
    builder: (_) => _ChatVideoComposer(videoFile: videoFile, onSend: onSend),
  );
}

class _ChatVideoComposer extends StatefulWidget {
  final File videoFile;
  final Future<void> Function({
    required String attachmentUrl,
    required String type,
    String? caption,
    required bool viewOnce,
  })
  onSend;

  const _ChatVideoComposer({required this.videoFile, required this.onSend});

  @override
  State<_ChatVideoComposer> createState() => _ChatVideoComposerState();
}

class _ChatVideoComposerState extends State<_ChatVideoComposer> {
  final _captionController = TextEditingController();
  VideoPlayerController? _controller;
  bool _viewOnce = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    final controller = VideoPlayerController.file(widget.videoFile);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
    } catch (_) {
      await controller.dispose();
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePreview() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      final result = await UploadService.uploadFile(widget.videoFile, 'chat');
      final url = result.rightOrNull;
      if (url == null) {
        if (mounted) {
          AppSnackbar.error(
            context,
            result.leftOrNull?.message ?? 'Erro ao enviar vídeo',
          );
        }
        return;
      }

      final caption = _captionController.text.trim();
      await widget.onSend(
        attachmentUrl: url,
        type: 'VIDEO',
        caption: caption.isEmpty ? null : caption,
        viewOnce: _viewOnce,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Erro ao enviar vídeo');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _togglePreview,
            child: Container(
              height: 280,
              color: context.surfaceColor,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (initialized && controller != null)
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  else
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (initialized && !(controller?.value.isPlaying ?? false))
                    Icon(
                      Icons.play_arrow,
                      color: context.textPrimary,
                      size: 42,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pré-visualização com som desligado',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
              ViewOnceToggle(
                enabled: _viewOnce,
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
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ADICIONAR LEGENDA',
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isBusy ? null : _send,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppColors.primaryContainer,
                child: _isBusy
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        'SEND',
                        textAlign: TextAlign.center,
                        style: AppTypography.button.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
