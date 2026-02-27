import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(feedProvider);
      if (currentState.posts.isEmpty && !currentState.isLoading) {
        ref.read(feedProvider.notifier).loadFeed(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Freebay',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppColors.white : AppColors.primaryPurple,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_outlined,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.send_outlined,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            icon: Icon(
              Icons.search_outlined,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () => context.push('/explore'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(isDark, feedState),
      ),
    );
  }

  Widget _buildBody(bool isDark, FeedState feedState) {
    final storiesAsync = ref.watch(storiesProvider);

    if (feedState.error != null && feedState.posts.isEmpty) {
      return _buildErrorState(isDark, feedState.error!);
    }

    if (feedState.posts.isEmpty && !feedState.isLoading) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(feedProvider.notifier).refresh();
      },
      color: AppColors.primaryPurple,
      child: ListView.builder(
        itemCount: feedState.posts.length + 1 + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                storiesAsync.when(
                  data: (stories) => _buildStoriesRow(isDark, stories),
                  loading: () => const SizedBox(height: 100),
                  error: (_, __) => const SizedBox(height: 100),
                ),
                _buildInputArea(isDark),
              ],
            );
          }
          if (index == feedState.posts.length + 1) {
            return _buildLoadingMore(isDark);
          }
          final post = feedState.posts[index - 1];
          return _buildPostItem(context, isDark, post, index - 1);
        },
      ),
    );
  }

  Widget _buildLoadingMore(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/create-post'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.lightGray,
              child: const Icon(Icons.person,
                  size: 16, color: AppColors.mediumGray),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No que você está pensando\nou vendendo?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.add,
              color: AppColors.primaryPurple,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesRow(bool isDark, StoriesResponse? storiesResponse) {
    final stories = storiesResponse?.stories ?? [];

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryItem(isDark);
          }
          final story = stories[index - 1];
          return _buildStoryItem(isDark, story, index - 1);
        },
      ),
    );
  }

  Widget _buildAddStoryItem(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => context.push('/create-story'),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adicionar',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(bool isDark, StoryEntity story, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          final stories = ref.read(storiesProvider).valueOrNull?.stories ?? [];
          if (stories.isNotEmpty) {
            final storyIndex = stories.indexWhere((s) => s.id == story.id);
            context.push('/story?index=$storyIndex');
          }
        },
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: story.isViewed
                      ? AppColors.mediumGray
                      : AppColors.primaryPurple,
                  width: 2,
                ),
                image: story.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(story.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
              ),
              child: story.imageUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.mediumGray)
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                story.user.displayName,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum post ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Siga usuários ou crie seu primeiro post!',
            style: TextStyle(
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar feed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(feedProvider.notifier).refresh(),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(
      BuildContext context, bool isDark, PostEntity post, int index) {
    final price = post.product?.price != null && post.product!.price > 0
        ? post.product!.price / 100
        : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: SocialPost(
        userId: post.user.id,
        userName: post.user.displayName,
        userAvatarUrl: post.user.avatarUrl,
        content: post.content,
        imageUrl: post.imageUrl,
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        sharesCount: post.sharesCount,
        isLiked: post.isLiked,
        price: price,
        onTap: () => context.push('/post/${post.id}'),
        onUserTap: () => context.push('/user/${post.user.id}'),
        onLike: () async {
          final authState = ref.read(authControllerProvider);
          final user = authState.valueOrNull;

          if (user == null || user.isGuest) {
            if (context.mounted) {
              AppSnackbar.warning(context, 'Faça login para curtir');
            }
            return false;
          }

          final notifier = ref.read(feedProvider.notifier);
          try {
            if (post.isLiked) {
              await ref.read(socialRepositoryProvider).unlikePost(post.id);
              notifier.updatePostLike(post.id, false, post.likesCount - 1);
            } else {
              await ref.read(socialRepositoryProvider).likePost(post.id);
              notifier.updatePostLike(post.id, true, post.likesCount + 1);
            }
            return true;
          } catch (e) {
            return false;
          }
        },
        onComment: () => context.push('/post/${post.id}/comments'),
        onShare: () {},
      ),
    );
  }
}
