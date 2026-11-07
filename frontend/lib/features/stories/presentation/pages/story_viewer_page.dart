import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/features/stories/presentation/widgets/story_page.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';

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
  StreamSubscription<NotificationSocketEvent>? _privacyEvents;
  bool _privateContentRemoved = false;
  bool _pinching = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _groupPageController = PageController(
      initialPage: widget.initialGroupIndex,
    );
    _privacyEvents = ref.read(notificationSocketServiceProvider).events.listen((
      event,
    ) {
      if (event is PrivateContentInvalidated) _removePrivateContent();
    });
    ref.listenManual(
      authControllerProvider.select((session) => session.value?.id),
      (previous, next) {
        if (previous != next) _removePrivateContent();
      },
    );
  }

  void _removePrivateContent() {
    if (!mounted ||
        _privateContentRemoved ||
        !widget.groups.any(
          (group) => group.stories.any(
            (story) => story.audience == StoryAudience.closeFriends,
          ),
        )) {
      return;
    }
    // ponytail: the empty invalidation event identifies no source; discard the
    // private snapshot and fetch a fresh one on the next open.
    setState(() => _privateContentRemoved = true);
    ref.invalidate(storiesProvider);
    for (final group in widget.groups) {
      ref.invalidate(userStoriesProvider(group.user.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  @override
  void dispose() {
    _privacyEvents?.cancel();
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
    if (_privateContentRemoved) {
      return Scaffold(
        backgroundColor: AppColors.onSurface,
        body: Center(child: Text(l10n(context).feedNoStories)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView.builder(
        physics: _pinching ? const NeverScrollableScrollPhysics() : null,
        controller: _groupPageController,
        onPageChanged: (idx) {
          setState(() {
            _currentGroupIndex = idx;
          });
        },
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          return GroupStoryViewer(
            key: ValueKey(widget.groups[index].user.id),
            group: widget.groups[index],
            isActive: index == _currentGroupIndex,
            onNextGroup: _nextGroup,
            onPrevGroup: _prevGroup,
            onClose: () => Navigator.pop(context),
            onPinchChanged: (pinching) {
              if (mounted && _pinching != pinching) {
                setState(() => _pinching = pinching);
              }
            },
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
  final ValueChanged<bool>? onPinchChanged;

  const GroupStoryViewer({
    super.key,
    required this.group,
    required this.isActive,
    required this.onNextGroup,
    required this.onPrevGroup,
    required this.onClose,
    this.onPinchChanged,
  });

  @override
  ConsumerState<GroupStoryViewer> createState() => _GroupStoryViewerState();
}

class _GroupStoryViewerState extends ConsumerState<GroupStoryViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  int _currentIndex = 0;
  bool _isPaused = false;
  int _activePointers = 0;
  bool _wasPinching = false;
  Timer? _holdTimer;
  bool _wasHeld = false;
  bool _isDraggingDown = false;
  double _dragOffset = 0;
  double _settleFrom = 0;
  bool _isSettlingDismiss = false;
  bool _lifecyclePaused = false;
  Offset _pointerDown = Offset.zero;
  String? _readyStoryId;
  String? _viewedStoryId;
  int _playbackEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      // This controller measures reading time, not decorative motion.
      animationBehavior: AnimationBehavior.preserve,
      duration: const Duration(seconds: 7),
    );
    _animController.addStatusListener(_onAnimStatus);
  }

  @override
  void didUpdateWidget(GroupStoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playbackEpoch++;
        _readyStoryId = null;
        _viewedStoryId = null;
        _animController.reset();
      } else {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isLifecyclePaused = state != AppLifecycleState.resumed;
    _lifecyclePaused = isLifecyclePaused;
    final shouldPause =
        isLifecyclePaused || _isSettlingDismiss || _activePointers > 0;
    if (_isPaused != shouldPause ||
        (isLifecyclePaused && _activePointers > 0)) {
      setState(() {
        _isPaused = shouldPause;
        if (isLifecyclePaused) _activePointers = 0;
      });
    }
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
        _readyStoryId = null;
        _viewedStoryId = null;
        _animController.reset();
      });
    } else {
      widget.onNextGroup();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isPaused = false;
        _readyStoryId = null;
        _viewedStoryId = null;
        _animController.reset();
      });
    } else {
      widget.onPrevGroup();
    }
  }

  Future<void> _markStoryViewed(String storyId) async {
    if (!widget.isActive ||
        _readyStoryId != storyId ||
        _viewedStoryId == storyId) {
      return;
    }
    _viewedStoryId = storyId;
    try {
      final repository = ref.read(storiesRepositoryProvider);
      await repository.viewStory(storyId);
    } catch (e) {
      // Silently fail
    }
  }

  void _onStoryReady(String storyId) {
    if (!mounted || widget.group.stories[_currentIndex].id != storyId) return;
    _readyStoryId = storyId;
    unawaited(_markStoryViewed(storyId));
  }

  void _onTapUp(TapUpDetails details) {
    if (_wasHeld) return;
    final storyIndex = _currentIndex;
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < width / 3) {
      _prevStory();
    } else if (dx > width * 2 / 3) {
      _nextStory();
    }
    if (storyIndex != _currentIndex) _activePointers = 0;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.position;
    _activePointers++;
    if (_activePointers > 1) {
      _holdTimer?.cancel();
      _wasHeld = true;
      _wasPinching = true;
      if (_isDraggingDown) {
        setState(() {
          _isDraggingDown = false;
          _settleFrom = _dragOffset;
          _dragOffset = 0;
        });
      }
      widget.onPinchChanged?.call(true);
    }
    if (_activePointers == 1) {
      _wasHeld = false;
      _wasPinching = false;
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 300), () {
        _wasHeld = true;
      });
    }
    if (!widget.isActive || _isPaused) return;
    setState(() => _isPaused = true);
  }

  void _onPointerEnd(PointerEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers == 0) {
      widget.onPinchChanged?.call(false);
      _holdTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _wasHeld = false);
    }
    if (!mounted ||
        !widget.isActive ||
        _activePointers > 0 ||
        !_isPaused ||
        _lifecyclePaused ||
        _isSettlingDismiss) {
      return;
    }
    setState(() => _isPaused = false);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (!widget.isActive || _wasPinching) return;
    final displacement = details.globalPosition - _pointerDown;
    if (displacement.dy <= displacement.dx.abs()) return;
    setState(() {
      _isDraggingDown = true;
      _isSettlingDismiss = true;
      _settleFrom = 0;
      _dragOffset = displacement.dy.clamp(
        0.0,
        MediaQuery.sizeOf(context).height,
      );
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_wasPinching) return;
    if (!_isDraggingDown) {
      _onVerticalDragStart(
        DragStartDetails(globalPosition: details.globalPosition),
      );
    }
    if (!_isDraggingDown) return;
    setState(() {
      _dragOffset = (details.globalPosition.dy - _pointerDown.dy).clamp(
        0.0,
        MediaQuery.sizeOf(context).height,
      );
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDraggingDown) return;
    _isDraggingDown = false;
    final height = MediaQuery.sizeOf(context).height;
    if (_dragOffset > height * 0.25 ||
        details.velocity.pixelsPerSecond.dy > 1000) {
      widget.onClose();
      return;
    }
    setState(() {
      _settleFrom = _dragOffset;
      _dragOffset = 0;
    });
  }

  void _onDismissSettleEnd() {
    if (!_isSettlingDismiss || _isDraggingDown || _dragOffset != 0) return;
    _isSettlingDismiss = false;
    if (mounted && !_lifecyclePaused && _activePointers == 0 && _isPaused) {
      setState(() => _isPaused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyItem = widget.group.stories[_currentIndex];
    final story = StoryEntity(
      id: storyItem.id,
      userId: widget.group.user.id,
      imageUrl: storyItem.imageUrl,
      mediaType: storyItem.mediaType,
      audience: storyItem.audience,
      caption: storyItem.caption,
      textBlocks: storyItem.textBlocks,
      expiresAt: storyItem.expiresAt,
      createdAt: storyItem.createdAt,
      user: widget.group.user,
    );

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: GestureDetector(
        onTapUp: _onTapUp,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: _settleFrom, end: _dragOffset),
          duration: _isDraggingDown
              ? Duration.zero
              : AppMotion.forContext(context, AppMotion.base),
          onEnd: _onDismissSettleEnd,
          builder: (context, offset, child) =>
              Transform.translate(offset: Offset(0, offset), child: child),
          child: Stack(
            children: [
              StoryPage(
                key: ValueKey('${story.id}-$_playbackEpoch'),
                story: story,
                animationController: _animController,
                isPaused: _isPaused || !widget.isActive,
                onComplete: _nextStory,
                onReady: () => _onStoryReady(story.id),
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
              ),
              _buildProgressBars(),
              _buildHeader(story),
            ],
          ),
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
                  Row(
                    children: [
                      if (story.audience == StoryAudience.closeFriends) ...[
                        const Icon(
                          Icons.group,
                          color: AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n(context).closeFriendsTitle,
                          style: AppTypography.brutalistTag.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatTime(context, story.createdAt),
                        style: TextStyle(
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n(context).accessibilityClose,
              icon: const Icon(Icons.close, color: AppColors.onPrimary),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return l10n(context).timeAgoNow;
    } else if (diff.inMinutes < 60) {
      return l10n(context).timeCompactMinutes(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n(context).timeCompactHours(diff.inHours);
    } else {
      return l10n(context).timeCompactDays(diff.inDays);
    }
  }
}
