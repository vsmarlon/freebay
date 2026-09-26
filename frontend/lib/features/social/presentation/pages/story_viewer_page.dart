import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_page.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final List<StoryGroupEntity> groups;
  final int initialGroupIndex;

  const StoryViewerPage({
    super.key,
    required this.groups,
    this.initialGroupIndex = 0,
  });

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  late PageController _groupPageController;
  late int _currentGroupIndex;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _groupPageController = PageController(
      initialPage: widget.initialGroupIndex,
    );
  }

  @override
  void dispose() {
    _groupPageController.dispose();
    super.dispose();
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.groups.length - 1) {
      _groupPageController.nextPage(
        duration: AppMotion.base,
        curve: AppMotion.baseCurve,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prevGroup() {
    if (_currentGroupIndex > 0) {
      _groupPageController.previousPage(
        duration: AppMotion.base,
        curve: AppMotion.baseCurve,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: PageView.builder(
        controller: _groupPageController,
        onPageChanged: (idx) {
          setState(() {
            _currentGroupIndex = idx;
          });
        },
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          return GroupStoryViewer(
            group: widget.groups[index],
            isActive: index == _currentGroupIndex,
            onNextGroup: _nextGroup,
            onPrevGroup: _prevGroup,
            onClose: () => Navigator.pop(context),
          );
        },
      ),
    );
  }
}

class GroupStoryViewer extends ConsumerStatefulWidget {
  final StoryGroupEntity group;
  final bool isActive;
  final VoidCallback onNextGroup;
  final VoidCallback onPrevGroup;
  final VoidCallback onClose;

  const GroupStoryViewer({
    super.key,
    required this.group,
    required this.isActive,
    required this.onNextGroup,
    required this.onPrevGroup,
    required this.onClose,
  });

  @override
  ConsumerState<GroupStoryViewer> createState() => _GroupStoryViewerState();
}

class _GroupStoryViewerState extends ConsumerState<GroupStoryViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _animController.addStatusListener(_onAnimStatus);
    _markStoryViewed(widget.group.stories[_currentIndex].id);
  }

  @override
  void didUpdateWidget(GroupStoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        if (!_isPaused) {
          // Play will happen via StoryPage updating
        }
      } else {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.group.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _isPaused = false;
        _animController.reset();
      });
      _markStoryViewed(widget.group.stories[_currentIndex].id);
    } else {
      widget.onNextGroup();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isPaused = false;
        _animController.reset();
      });
      _markStoryViewed(widget.group.stories[_currentIndex].id);
    } else {
      widget.onPrevGroup();
    }
  }

  Future<void> _markStoryViewed(String storyId) async {
    try {
      final repository = ref.read(socialRepositoryProvider);
      await repository.viewStory(storyId);
    } catch (e) {
      // Silently fail
    }
  }

  void _onTapUp(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < width / 3) {
      _prevStory();
    } else if (dx > width * 2 / 3) {
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() => _isPaused = true);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() => _isPaused = false);
  }

  void _onLongPressCancel() {
    setState(() => _isPaused = false);
  }

  @override
  Widget build(BuildContext context) {
    final storyItem = widget.group.stories[_currentIndex];
    final story = StoryEntity(
      id: storyItem.id,
      userId: widget.group.user.id,
      imageUrl: storyItem.imageUrl,
      mediaType: storyItem.mediaType,
      caption: storyItem.caption,
      textBlocks: storyItem.textBlocks,
      expiresAt: storyItem.expiresAt,
      createdAt: storyItem.createdAt,
      user: widget.group.user,
    );

    return GestureDetector(
      onTapUp: _onTapUp,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: Stack(
        children: [
          StoryPage(
            key: ValueKey(story.id),
            story: story,
            animationController: _animController,
            isPaused: _isPaused || !widget.isActive,
            onComplete: _nextStory,
          ),
          _buildProgressBars(),
          _buildHeader(story),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(widget.group.stories.length, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 2,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  double value = 0.0;
                  if (index < _currentIndex) {
                    value = 1.0;
                  } else if (index == _currentIndex) {
                    value = _animController.value;
                  }
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.onPrimary,
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(StoryEntity story) {
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
              onPressed: widget.onClose,
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
