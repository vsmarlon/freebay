import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/widgets/story_canvas.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';

class StoryPage extends StatefulWidget {
  final StoryEntity story;
  final AnimationController animationController;
  final bool isPaused;
  final VoidCallback onComplete;

  const StoryPage({
    super.key,
    required this.story,
    required this.animationController,
    required this.isPaused,
    required this.onComplete,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  VideoPlayerController? _videoController;
  bool _imageReady = false;
  bool _mediaError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    if (widget.story.mediaType == StoryMediaType.video) {
      _initializeVideo();
    } else {
      widget.animationController.duration = const Duration(seconds: 7);
      widget.animationController.stop();
    }
  }

  void _startImageTimer() {
    if (!mounted ||
        _imageReady ||
        widget.story.mediaType != StoryMediaType.image) {
      return;
    }
    _imageReady = true;
    if (!widget.isPaused) widget.animationController.forward();
  }

  Future<void> _initializeVideo() async {
    final url = widget.story.imageUrl;
    try {
      final headers = await getMediaAuthHeadersAsync(url);
      if (!mounted || widget.story.imageUrl != url) return;
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers ?? const {},
      );
      _videoController = controller;
      controller.addListener(_onVideoUpdate);
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (!mounted || !identical(_videoController, controller)) return;
      final duration = controller.value.duration;
      widget.animationController.duration = duration > Duration.zero
          ? duration
          : const Duration(seconds: 1);
      setState(() {});
      if (!widget.isPaused) {
        await controller.play();
      }
    } catch (_) {
      final controller = _videoController;
      controller?.removeListener(_onVideoUpdate);
      await controller?.dispose();
      _videoController = null;
      if (mounted) setState(() => _mediaError = true);
    }
  }

  void _onVideoUpdate() {
    final controller = _videoController;
    if (!mounted || controller?.value.isInitialized != true) return;
    final duration = controller!.value.duration;
    if (duration <= Duration.zero) return;
    final progress =
        (controller.value.position.inMicroseconds / duration.inMicroseconds)
            .clamp(0.0, 1.0);
    widget.animationController.value = progress;
  }

  Future<void> _retryMedia() async {
    setState(() {
      _mediaError = false;
      _imageReady = false;
    });
    if (widget.story.mediaType == StoryMediaType.video) {
      final controller = _videoController;
      controller?.removeListener(_onVideoUpdate);
      await controller?.dispose();
      _videoController = null;
      await _initializeVideo();
    } else {
      await NetworkImage(
        widget.story.imageUrl,
        headers: mediaAuthHeaders(widget.story.imageUrl),
      ).evict();
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.story.id != oldWidget.story.id) {
      _videoController?.dispose();
      _videoController = null;
      _imageReady = false;
      _mediaError = false;
      widget.animationController.reset();
      _setupAnimation();
    } else if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        widget.animationController.stop();
        _videoController?.pause();
      } else {
        if (widget.story.mediaType == StoryMediaType.image && _imageReady ||
            widget.story.mediaType == StoryMediaType.video &&
                _videoController?.value.isInitialized == true) {
          if (widget.story.mediaType == StoryMediaType.image) {
            widget.animationController.forward();
          }
          _videoController?.play();
        }
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onSurface,
      child: StoryCanvas(
        blocks: widget.story.textBlocks ?? const [],
        background: Stack(
          children: [
            Center(
              child: widget.story.mediaType == StoryMediaType.video
                  ? _mediaError
                        ? _buildMediaError()
                        : _videoController?.value.isInitialized == true
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(
                            color: AppColors.onPrimary,
                          )
                  : Image.network(
                      widget.story.imageUrl,
                      headers: mediaAuthHeaders(widget.story.imageUrl),
                      cacheWidth:
                          (MediaQuery.sizeOf(context).width *
                                  MediaQuery.devicePixelRatioOf(context))
                              .ceil()
                              .clamp(1, 1440),
                      fit: BoxFit.contain,
                      frameBuilder: (context, child, frame, wasSync) {
                        if (frame != null || wasSync) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _startImageTimer(),
                          );
                        }
                        return child;
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildMediaError(),
                    ),
            ),
            if (widget.story.caption?.isNotEmpty == true)
              Positioned(
                left: 16,
                right: 16,
                bottom: 72,
                child: Text(
                  widget.story.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image, color: AppColors.onPrimary, size: 48),
        Text(
          l10n(context).errorUnknown,
          style: const TextStyle(color: AppColors.onPrimary),
        ),
        TextButton.icon(
          onPressed: _retryMedia,
          icon: const Icon(Icons.refresh, color: AppColors.onPrimary),
          label: Text(l10n(context).commonRetry),
        ),
        TextButton(
          onPressed: widget.onComplete,
          child: Text(l10n(context).storiesSkip),
        ),
      ],
    ),
  );
}
