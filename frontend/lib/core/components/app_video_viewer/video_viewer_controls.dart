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
        Semantics(
          button: true,
          label: 'Tentar novamente',
          onTap: onRetry,
          child: GestureDetector(
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
      child: Semantics(
        button: true,
        label: isCompleted ? 'Reproduzir novamente' : 'Reproduzir vídeo',
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
              IconButton(
                tooltip: 'Fechar vídeo',
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  fixedSize: const Size(44, 44),
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
                  Semantics(
                    slider: true,
                    label: 'Posição do vídeo',
                    value:
                        '${_formatDuration(position)} de ${_formatDuration(duration)}',
                    increasedValue: _formatDuration(
                      _stepPosition(position, duration, true),
                    ),
                    decreasedValue: _formatDuration(
                      _stepPosition(position, duration, false),
                    ),
                    onIncrease: () => controller.seekTo(
                      _stepPosition(position, duration, true),
                    ),
                    onDecrease: () => controller.seekTo(
                      _stepPosition(position, duration, false),
                    ),
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primaryContainer,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: isCompleted
                            ? 'Reproduzir novamente'
                            : isPlaying
                            ? 'Pausar vídeo'
                            : 'Reproduzir vídeo',
                        child: GestureDetector(
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
                      Semantics(
                        button: true,
                        label: controller.value.volume == 0
                            ? 'Ativar som'
                            : 'Desativar som',
                        child: GestureDetector(
                          onTap: onToggleMute,
                          child: Icon(
                            controller.value.volume == 0
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: Colors.white,
                            size: 24,
                          ),
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

  Duration _stepPosition(Duration position, Duration duration, bool forward) {
    const step = Duration(seconds: 5);
    if (forward) {
      final next = position + step;
      return next > duration ? duration : next;
    }
    final previous = position - step;
    return previous < Duration.zero ? Duration.zero : previous;
  }
}
