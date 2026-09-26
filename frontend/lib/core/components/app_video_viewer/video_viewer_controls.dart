import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:video_player/video_player.dart';

class VideoViewerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const VideoViewerError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryContainer,
            child: Text(
              'Tentar novamente',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class VideoViewerCenterButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const VideoViewerCenterButton({
    super.key,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
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
    );
  }
}

class VideoViewerCloseButton extends StatelessWidget {
  final VoidCallback onClose;

  const VideoViewerCloseButton({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoViewerControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isPlaying;
  final bool isCompleted;
  final Duration position;
  final Duration duration;
  final VoidCallback onClose;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;

  const VideoViewerControls({
    super.key,
    required this.controller,
    required this.isPlaying,
    required this.isCompleted,
    required this.position,
    required this.duration,
    required this.onClose,
    required this.onTogglePlay,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VideoViewerCloseButton(onClose: onClose),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        onTap: onTogglePlay,
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
                        onTap: onToggleMute,
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
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
