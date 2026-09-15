import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:video_player/video_player.dart';

Future<void> showFullScreenVideo(BuildContext context, String videoUrl) async {
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: AppMotion.enter,
      pageBuilder: (_, _, _) => _AppVideoViewer(videoUrl: videoUrl),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _AppVideoViewer extends StatefulWidget {
  final String videoUrl;

  const _AppVideoViewer({required this.videoUrl});

  @override
  State<_AppVideoViewer> createState() => _AppVideoViewerState();
}

class _AppVideoViewerState extends State<_AppVideoViewer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _startHideControlsTimer();
    }
  }

  Future<void> _initialize() async {
    final rawUrl = widget.videoUrl;
    final resolvedUrl = mediaUrl(rawUrl);
    final uri = Uri.tryParse(resolvedUrl);

    if (uri != null && uri.isScheme('file')) {
      await _initFileController(File(uri.toFilePath()));
      return;
    } else if (rawUrl.startsWith('/') &&
        !rawUrl.startsWith('/media/') &&
        !rawUrl.startsWith('/uploads/') &&
        File(rawUrl).existsSync()) {
      await _initFileController(File(rawUrl));
      return;
    }

    // 1. Try native streaming
    try {
      final headers =
          await getMediaAuthHeadersAsync(resolvedUrl) ??
          const <String, String>{};
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: headers,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onControllerUpdate);
      setState(() => _controller = controller);
      await controller.play();
      _startHideControlsTimer();
      return;
    } catch (_) {
      // Fall through to download fallback
    }

    // 2. Resilient fallback: download bytes via HttpClient and play from local file
    try {
      final response = await HttpClient.instance.get<List<int>>(
        resolvedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) throw const FormatException('Vídeo vazio');

      final ext = resolvedUrl.contains('.')
          ? '.${resolvedUrl.split('.').last.split('?').first}'
          : '.mp4';
      final file = File(
        '${Directory.systemTemp.path}/freebay_view_${resolvedUrl.hashCode.toUnsigned(32)}$ext',
      );
      await file.writeAsBytes(bytes, flush: true);
      await _initFileController(file);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar o vídeo.');
      }
    }
  }

  Future<void> _initFileController(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onControllerUpdate);
      setState(() => _controller = controller);
      await controller.play();
      _startHideControlsTimer();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar o vídeo.');
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
      _hideControlsTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      if (controller.value.position >= controller.value.duration) {
        controller.seekTo(Duration.zero);
      }
      controller.play();
      _startHideControlsTimer();
      setState(() {});
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    final isMuted = controller.value.volume == 0.0;
    controller.setVolume(isMuted ? 1.0 : 0.0);
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized = controller?.value.isInitialized ?? false;
    final isPlaying = controller?.value.isPlaying ?? false;
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;
    final isCompleted =
        isInitialized && duration > Duration.zero && position >= duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Dismissible(
              key: const Key('video_viewer'),
              direction: DismissDirection.vertical,
              onDismissed: (_) => Navigator.of(context).pop(),
              child: Center(
                child: _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => setState(() {
                              _error = null;
                              _controller = null;
                              _initialize();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: AppColors.primaryContainer,
                              child: Text(
                                'Tentar novamente',
                                style: AppTypography.button.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : isInitialized && controller != null
                    ? GestureDetector(
                        onTap: _toggleControls,
                        behavior: HitTestBehavior.opaque,
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : const CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
              ),
            ),
          ),
          if (isInitialized && (!isPlaying || isCompleted))
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Icon(
                    isCompleted ? Icons.replay : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          if (_showControls) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isInitialized && controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: AppColors.primaryContainer,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Icon(
                                isCompleted
                                    ? Icons.replay
                                    : isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleMute,
                              child: Icon(
                                controller.value.volume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
