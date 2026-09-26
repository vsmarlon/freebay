import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:video_player/video_player.dart';

class VideoSourceResolver {
  const VideoSourceResolver();

  Future<VideoPlayerController> createController(String rawUrl) async {
    final resolvedUrl = mediaUrl(rawUrl);
    final uri = Uri.tryParse(resolvedUrl);

    if (uri != null && uri.isScheme('file')) {
      return _createFileController(File(uri.toFilePath()));
    }
    if (rawUrl.startsWith('/') &&
        !rawUrl.startsWith('/media/') &&
        !rawUrl.startsWith('/uploads/')) {
      final file = File(rawUrl);
      if (file.existsSync()) return _createFileController(file);
    }

    try {
      final headers =
          await getMediaAuthHeadersAsync(resolvedUrl) ??
          const <String, String>{};
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: headers,
      );
      await controller.initialize();
      return controller;
    } catch (_) {
      return _downloadAndCreateController(resolvedUrl);
    }
  }

  Future<VideoPlayerController> _downloadAndCreateController(
    String resolvedUrl,
  ) async {
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
    return _createFileController(file);
  }

  Future<VideoPlayerController> _createFileController(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }
}
