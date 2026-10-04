import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/core/components/app_video_viewer.dart';
import 'package:freebay/core/components/app_video_viewer/video_source_resolver.dart';

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
  bool _thumbnailFailed = false;
  int _initialization = 0;
  final _resolver = const VideoSourceResolver();

  String? get _url {
    final value = widget.videoUrl;
    return value == null || value.isEmpty ? null : mediaUrl(value);
  }

  String? get _thumbnailUrl {
    final value = widget.thumbnailUrl?.trim();
    if (value == null || value.isEmpty) return null;
    final resolved = mediaUrl(value);
    final uri = Uri.tryParse(resolved);
    return uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty
        ? resolved
        : null;
  }

  @override
  void initState() {
    super.initState();
    if (_thumbnailUrl == null) _initialize(play: false);
  }

  @override
  void didUpdateWidget(VideoMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initialization++;
      _controller?.dispose();
      _controller = null;
      _error = null;
      _thumbnailFailed = false;
      _loading = false;
      if (_thumbnailUrl == null) _initialize(play: false);
    } else if (oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _thumbnailFailed = false;
      if (_thumbnailUrl == null && _controller == null) {
        _initialize(play: false);
      }
    }
  }

  Future<void> _initialize({required bool play}) async {
    final url = _url;
    if (url == null) return;
    if (_loading) return;
    final initialization = ++_initialization;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final controller = await _resolver.createController(url);
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted || initialization != _initialization) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      if (play) await controller.play();
    } catch (_) {
      if (mounted && initialization == _initialization) {
        setState(() => _error = l10n(context).errorUnknown);
      }
    } finally {
      if (mounted && initialization == _initialization) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) {
      await _initialize(play: true);
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openFullscreen(String url) async {
    final controller = _controller;
    if (controller != null) {
      _controller = null;
      setState(() {});
    }
    await showFullScreenVideo(context, url, controller: controller);
    if (mounted && controller != null && _thumbnailUrl == null) {
      await _initialize(play: false);
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    await controller.setVolume(_muted ? 0 : 1);
    if (mounted) setState(() {});
  }

  void _onThumbnailError() {
    if (!mounted || _thumbnailFailed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _thumbnailFailed) return;
      setState(() => _thumbnailFailed = true);
      _initialize(play: false);
    });
  }

  String _duration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _initialization++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return const SizedBox.shrink();

    final thumbnailUrl = _thumbnailUrl;
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
              onTap: _loading ? null : () => _openFullscreen(url),
              behavior: HitTestBehavior.opaque,
              child: AspectRatio(
                aspectRatio: initialized
                    ? controller!.value.aspectRatio
                    : 16 / 9,
                child: initialized && controller != null
                    ? VideoPlayer(controller)
                    : thumbnailUrl == null || _thumbnailFailed
                    ? ColoredBox(color: context.surfaceMidColor)
                    : CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        httpHeaders: mediaAuthHeaders(thumbnailUrl),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          _onThumbnailError();
                          return ColoredBox(color: context.surfaceMidColor);
                        },
                      ),
              ),
            ),
            if (!initialized || !(controller?.value.isPlaying ?? false))
              IconButton(
                onPressed: _loading ? null : _togglePlayback,
                tooltip: l10n(context).accessibilityPlayVideo,
                icon: Icon(
                  _loading ? Icons.downloading : Icons.play_arrow,
                  color: context.textPrimary,
                  size: 42,
                ),
              ),
            if (_error != null)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _initialize(play: false),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n(context).commonRetry),
                      ),
                    ],
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
                  semanticLabel: _muted
                      ? l10n(context).accessibilityUnmuteVideo
                      : l10n(context).accessibilityMuteVideo,
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
