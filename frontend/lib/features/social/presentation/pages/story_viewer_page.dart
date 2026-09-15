import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/features/social/presentation/widgets/story_canvas.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final List<StoryEntity> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isPaused = false;
    });
    _markStoryViewed(widget.stories[index].id);
  }

  Future<void> _markStoryViewed(String storyId) async {
    try {
      final repository = ref.read(socialRepositoryProvider);
      await repository.viewStory(storyId);
    } catch (e) {
      // Silently fail - viewer count is not critical
    }
  }

  void _onTapDown(TapDownDetails details, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < width / 3) {
      // Tap on left side - go to previous story
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: AppMotion.base,
          curve: AppMotion.baseCurve,
        );
      } else {
        Navigator.pop(context);
      }
    } else if (dx > width * 2 / 3) {
      // Tap on right side - go to next story
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: AppMotion.base,
          curve: AppMotion.baseCurve,
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      // Tap in middle - toggle pause
      setState(() {
        _isPaused = !_isPaused;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details, context),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _StoryPage(
                  key: ValueKey(story.id),
                  story: story,
                  isPaused: _isPaused,
                  onComplete: () {
                    if (index < widget.stories.length - 1) {
                      _pageController.nextPage(
                        duration: AppMotion.base,
                        curve: AppMotion.baseCurve,
                      );
                    } else if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
            _buildProgressBars(),
            _buildHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 2,
              child: LinearProgressIndicator(
                value: index < _currentIndex
                    ? 1.0
                    : index == _currentIndex
                    ? (_isPaused ? 0.0 : null)
                    : 0.0,
                backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.onPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final story = widget.stories[_currentIndex];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.bgColor,
                image: story.user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(story.user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: story.user.avatarUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.user.displayName,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatTime(story.createdAt),
                    style: TextStyle(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}

class _StoryPage extends StatefulWidget {
  final StoryEntity story;
  final bool isPaused;
  final VoidCallback onComplete;

  const _StoryPage({
    super.key,
    required this.story,
    required this.isPaused,
    required this.onComplete,
  });

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    if (widget.story.mediaType == 'VIDEO') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.story.imageUrl),
      );
      _initializeVideo();
    }

    if (!widget.isPaused) {
      _animationController.forward();
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_completed) {
          _completed = true;
          widget.onComplete();
        }
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController!.initialize();
      if (!mounted) return;
      _animationController.duration = _videoController!.value.duration;
      setState(() {});
      _videoController?.addListener(_videoProgress);
      if (!widget.isPaused) await _videoController?.play();
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _videoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_completed &&
        controller.value.position >= controller.value.duration &&
        mounted) {
      _completed = true;
      widget.onComplete();
    }
  }

  @override
  void didUpdateWidget(_StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _animationController.stop();
        _videoController?.pause();
      } else {
        _animationController.forward();
        _videoController?.play();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.removeListener(_videoProgress);
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
              child: widget.story.mediaType == 'VIDEO'
                  ? _videoController?.value.isInitialized == true
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: Colors.white)
                  : Image.network(
                      widget.story.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.onPrimary.withAlpha(138),
                          size: 64,
                        ),
                      ),
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
