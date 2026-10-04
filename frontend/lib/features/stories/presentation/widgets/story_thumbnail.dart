import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/shared/utils/media_url.dart';

class StoryThumbnail extends StatefulWidget {
  const StoryThumbnail({super.key, required this.url, required this.mediaType});

  final String url;
  final StoryMediaType mediaType;

  @override
  State<StoryThumbnail> createState() => _StoryThumbnailState();
}

class _StoryThumbnailState extends State<StoryThumbnail> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    if (widget.mediaType != StoryMediaType.video) return;
    final url = widget.url;
    final headers = await getMediaAuthHeadersAsync(url);
    if (!mounted || widget.url != url) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers ?? const {},
    );
    _video = controller;
    try {
      await controller.initialize();
      if (mounted && identical(_video, controller)) setState(() {});
    } catch (_) {
      if (mounted && identical(_video, controller)) setState(() {});
    }
  }

  @override
  void didUpdateWidget(StoryThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url ||
        widget.mediaType != oldWidget.mediaType) {
      _video?.dispose();
      _video = null;
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: ColoredBox(
      color: context.surfaceMidColor,
      child: widget.mediaType == StoryMediaType.image
          ? isPrivateMedia(widget.url)
                ? Image.network(
                    widget.url,
                    headers: mediaAuthHeaders(widget.url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (_video?.value.isInitialized == true)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _video!.value.size.width,
                      height: _video!.value.size.height,
                      child: VideoPlayer(_video!),
                    ),
                  ),
                const Center(
                  child: Icon(Icons.play_arrow, color: AppColors.onPrimary),
                ),
              ],
            ),
    ),
  );
}
