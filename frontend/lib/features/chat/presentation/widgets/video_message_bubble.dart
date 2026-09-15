import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/core/components/app_video_viewer.dart';

class VideoMessageBubble extends StatefulWidget {
  final String? videoUrl;
  final bool isMe;
  final String? thumbnailUrl;

  const VideoMessageBubble({
    super.key,
    required this.videoUrl,
    required this.isMe,
    this.thumbnailUrl,
  });

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _muted = true;
  String? _error;

  String? get _url {
    final value = widget.videoUrl;
    return value == null || value.isEmpty ? null : mediaUrl(value);
  }

  Future<void> _togglePlayback() async {
    final url = _url;
    if (url == null) return;

    if (_controller == null) {
      if (_loading) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      // 1. Try direct native streaming first
      try {
        final uri = Uri.parse(url);
        final headers =
            await getMediaAuthHeadersAsync(url) ?? const <String, String>{};
        final controller = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: headers,
        );
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(_muted ? 0 : 1);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() => _controller = controller);
        await controller.play();
        if (mounted) setState(() => _loading = false);
        return;
      } catch (_) {
        // Fall back to download fallback
      }

      // 2. Resilient fallback: download bytes through HttpClient and play local file
      try {
        final response = await HttpClient.instance.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes == null) throw const FormatException('Vídeo vazio');
        final ext = url.contains('.')
            ? '.${url.split('.').last.split('?').first}'
            : '.mp4';
        final file = File(
          '${Directory.systemTemp.path}/freebay_bubble_${url.hashCode.toUnsigned(32)}$ext',
        );
        await file.writeAsBytes(bytes, flush: true);
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(_muted ? 0 : 1);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() => _controller = controller);
        await controller.play();
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Não foi possível carregar o vídeo.';
          });
        }
        return;
      }
      if (mounted) setState(() => _loading = false);
      return;
    }

    final controller = _controller!;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  String _duration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return const SizedBox.shrink();

    final controller = _controller;
    final initialized = controller?.value.isInitialized == true;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.isMe ? context.surfaceHighColor : context.surfaceColor,
          border: Border.all(color: context.borderColor),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                showFullScreenVideo(context, url);
              },
              child: AspectRatio(
                aspectRatio: initialized
                    ? controller!.value.aspectRatio
                    : 16 / 9,
                child: initialized && controller != null
                    ? VideoPlayer(controller)
                    : widget.thumbnailUrl == null
                    ? ColoredBox(color: context.surfaceMidColor)
                    : CachedNetworkImage(
                        imageUrl: mediaUrl(widget.thumbnailUrl!),
                        httpHeaders: mediaAuthHeaders(
                          mediaUrl(widget.thumbnailUrl!),
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (!initialized || !(controller?.value.isPlaying ?? false))
              IconButton(
                onPressed: _loading ? null : _togglePlayback,
                icon: Icon(
                  _loading ? Icons.downloading : Icons.play_arrow,
                  color: context.textPrimary,
                  size: 42,
                ),
              ),
            if (_error != null)
              Positioned.fill(
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textPrimary),
                  ),
                ),
              ),
            if (initialized)
              Positioned(
                left: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: Text(
                    _duration(controller!.value.duration),
                    style: TextStyle(color: context.textPrimary),
                  ),
                ),
              ),
            if (initialized)
              Positioned(
                right: 4,
                bottom: 4,
                child: BrutalistIconButton(
                  icon: _muted ? Icons.volume_off : Icons.volume_up,
                  iconColor: context.textPrimary,
                  onTap: _toggleMute,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
