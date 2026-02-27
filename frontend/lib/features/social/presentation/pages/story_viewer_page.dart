import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Navigator.pop(context);
      }
    } else if (dx > width * 2 / 3) {
      // Tap on right side - go to next story
      if (_currentIndex < widget.stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
      backgroundColor: Colors.black,
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
                return _StoryPage(story: story, isPaused: _isPaused);
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: index < _currentIndex
                      ? 1.0
                      : index == _currentIndex
                          ? (_isPaused ? 0.0 : null)
                          : 0.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.lightGray,
              backgroundImage: story.user.avatarUrl != null
                  ? NetworkImage(story.user.avatarUrl!)
                  : null,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatTime(story.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
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

  const _StoryPage({
    required this.story,
    required this.isPaused,
  });

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    if (!widget.isPaused) {
      _animationController.forward();
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animation completed - handled by PageView
      }
    });
  }

  @override
  void didUpdateWidget(_StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _animationController.stop();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Image.network(
          widget.story.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const CircularProgressIndicator(
              color: AppColors.primaryPurple,
            );
          },
        ),
      ),
    );
  }
}
