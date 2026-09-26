import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:video_player/video_player.dart';
import 'app_video_viewer/video_source_resolver.dart';
import 'app_video_viewer/video_viewer_controls.dart';

const videoControlsHideDelay = Duration(seconds: 3);

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
  final _resolver = const VideoSourceResolver();
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
    _hideControlsTimer = Timer(videoControlsHideDelay, () {
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
    try {
      final controller = await _resolver.createController(widget.videoUrl);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onControllerUpdate);
      setState(() => _controller = controller);
      await controller.play();
      _startHideControlsTimer();
    } catch (_) {
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

  Future<void> _retry() async {
    final controller = _controller;
    controller?.removeListener(_onControllerUpdate);
    await controller?.dispose();
    if (!mounted) return;
    setState(() {
      _error = null;
      _controller = null;
    });
    await _initialize();
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
                    ? VideoViewerError(message: _error!, onRetry: _retry)
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
            VideoViewerCenterButton(
              isCompleted: isCompleted,
              onTap: _togglePlayPause,
            ),
          if (_showControls && (!isInitialized || controller == null))
            VideoViewerCloseButton(onClose: () => Navigator.of(context).pop()),
          if (_showControls && isInitialized && controller != null)
            VideoViewerControls(
              controller: controller,
              isPlaying: isPlaying,
              isCompleted: isCompleted,
              position: position,
              duration: duration,
              onClose: () => Navigator.of(context).pop(),
              onTogglePlay: _togglePlayPause,
              onToggleMute: _toggleMute,
            ),
        ],
      ),
    );
  }
}
