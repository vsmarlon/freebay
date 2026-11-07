import 'dart:io';
import 'dart:ui';

import 'package:video_player/video_player.dart';

class VideoProbe {
  /// Abre e inicializa o VideoPlayerController para obter dimensões e duração.
  static Future<(VideoPlayerController, Size, int)> open(String path) async {
    final c = VideoPlayerController.file(
      File(path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    await c.initialize();
    final size = c.value.size;
    final durationMs = c.value.duration.inMilliseconds;
    return (c, size, durationMs);
  }
}
