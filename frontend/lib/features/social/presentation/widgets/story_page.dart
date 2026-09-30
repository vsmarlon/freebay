import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/widgets/story_canvas.dart';
import 'package:video_player/video_player.dart';
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
      await controller.initialize();
      if (!mounted || !identical(_videoController, controller)) return;
      final duration = controller.value.duration;
      widget.animationController.duration =
          duration > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : duration;
      setState(() {});
      if (!widget.isPaused) {
        await controller.play();
        widget.animationController.forward();
      }
    } catch (_) {
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
          widget.animationController.forward();
          _videoController?.play();
        }
      }
    }
  }

  @override
  void dispose() {
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
                  ? _videoController?.value.isInitialized == true
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: Colors.white)
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
                      errorBuilder: (context, error, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _startImageTimer(),
                        );
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.onPrimary.withAlpha(138),
                            size: 64,
                          ),
                        );
                      },
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
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
