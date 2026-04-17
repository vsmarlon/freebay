import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/app_dialog.dart';
import 'package:freebay/core/freebay.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';

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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(feedProvider);
      final feedType = ref.read(feedTypeProvider);
      if (currentState.posts.isEmpty && !currentState.isLoading) {
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
              feedType:
                  feedType == FeedType.following ? 'following' : 'explore',
            );
      }
      ref.read(likesProvider.notifier).initializeFromPosts(currentState.posts);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFeedTypeChanged(FeedType type) {
    ref.read(feedTypeProvider.notifier).state = type;
    ref.read(feedProvider.notifier).loadFeed(
          refresh: true,
          feedType: type == FeedType.following ? 'following' : 'explore',
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      body: Column(
        children: [
          _BrutalistHeader(isDark: isDark),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBody(isDark, feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, FeedState feedState) {
    final storiesAsync = ref.watch(storiesProvider);
    final feedType = ref.watch(feedTypeProvider);
    final contentFilter = ref.watch(feedContentFilterProvider);
    final filteredPosts = feedState.posts
        .where((post) => _matchesContentFilter(post, contentFilter))
        .toList();

    if (feedState.posts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(likesProvider.notifier).initializeFromPosts(feedState.posts);
      });
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return _buildErrorState(isDark, feedState.error!);
    }

    if (feedState.posts.isEmpty && !feedState.isLoading) {
      return _buildEmptyState(isDark);
    }

    if (filteredPosts.isEmpty && !feedState.isLoading) {
      return _buildEmptyState(
        isDark,
        message: 'NADA NESTE FILTRO',
        subtitle: 'Troque entre posts sociais e vendas quando quiser.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final type = ref.read(feedTypeProvider);
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
              feedType: type == FeedType.following ? 'following' : 'explore',
            );
      },
      color: AppColors.primaryContainer,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredPosts.length + 1 + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildFeedTitle(isDark, feedType, contentFilter),
                storiesAsync.when(
                  data: (stories) => _buildStoriesRow(isDark, stories),
                  loading: () => const SizedBox(height: 100),
                  error: (_, __) => const SizedBox(height: 100),
                ),
                _buildInputArea(isDark),
              ],
            );
          }
          if (index == filteredPosts.length + 1) {
            return _buildLoadingMore(isDark);
          }
          final post = filteredPosts[index - 1];
          return _buildPostItem(context, isDark, post, index - 1);
        },
      ),
    );
  }

  Widget _buildFeedTitle(
    bool isDark,
    FeedType feedType,
    FeedContentFilter contentFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FEED',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                  height: 0.9,
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
              Freebay.horizontalSpacing8,
              _FeedTypeDropdown(
                currentType: feedType,
                onChanged: _onFeedTypeChanged,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeedContentFilterBar(
            currentFilter: contentFilter,
            onChanged: (filter) =>
                ref.read(feedContentFilterProvider.notifier).state = filter,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore(bool isDark) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.primaryContainer,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return GestureDetector(
      onTap: () => _openCreateChooser(isDark),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: Colors.white,
              ),
            ),
            Freebay.horizontalSpacing8,
            Expanded(
              child: Text(
                'Criar post social ou anuncio de venda',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.outline,
                ),
              ),
            ),
            const Icon(
              Icons.add,
              color: AppColors.primaryContainer,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateChooser(bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateComposerSheet(isDark: isDark);
      },
    );
  }

  bool _matchesContentFilter(
    PostEntity post,
    FeedContentFilter contentFilter,
  ) {
    switch (contentFilter) {
      case FeedContentFilter.socialOnly:
        return post.type != 'PRODUCT';
      case FeedContentFilter.sellingOnly:
        return post.type == 'PRODUCT';
      case FeedContentFilter.all:
        return true;
    }
  }

  Widget _buildStoriesRow(bool isDark, StoriesResponse? storiesResponse) {
    final stories = storiesResponse?.stories ?? [];

    return SizedBox(
      height: 96,
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/create-story');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainer,
                border: Border.all(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                'Adicionar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
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

  Widget _buildStoryItem(bool isDark, StoryEntity story, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final stories = ref.read(storiesProvider).valueOrNull?.stories ?? [];
          if (stories.isNotEmpty) {
            final storyIndex = stories.indexWhere((s) => s.id == story.id);
            context.push('/story?index=$storyIndex');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: story.isViewed
                      ? AppColors.outline
                      : AppColors.primaryContainer,
                  width: 2,
                ),
                image: story.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(story.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainer,
              ),
              child: story.imageUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppColors.outline,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                story.user.displayName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
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

  Widget _buildEmptyState(bool isDark, {String? message, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainer,
                border: Border.all(color: AppColors.outline, width: 2),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 40,
                color: AppColors.outline,
              ),
            ),
            Freebay.verticalSpacing24,
            Text(
              message ?? 'NENHUM POST AINDA',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
            ),
            Freebay.verticalSpacing8,
            Text(
              subtitle ?? 'Siga usuários ou crie seu primeiro post!',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppDialog.showError(
        context: context,
        title: 'Erro ao carregar',
        subtitle: error,
        onOk: () {
          if (mounted) {
            final type = ref.read(feedTypeProvider);
            ref.read(feedProvider.notifier).loadFeed(
                  refresh: true,
                  feedType:
                      type == FeedType.following ? 'following' : 'explore',
                );
          }
        },
      );
    });

    return _buildEmptyState(isDark,
        message: 'ERRO AO CARREGAR',
        subtitle: 'Verifique sua conexão e tente novamente');
  }

  Widget _buildPostItem(
      BuildContext context, bool isDark, PostEntity post, int index) {
    final price = post.product?.price != null && post.product!.price > 0
        ? post.product!.price / 100
        : null;

    final likesState = ref.watch(likesProvider);
    final isLiked = likesState.isLiked(post.id);
    final likesCount = likesState.getLikeCount(post.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!likesState.likedPostIds.contains(post.id) ||
          !likesState.likeCounts.containsKey(post.id)) {
        ref.read(likesProvider.notifier).initializeSinglePost(
              post.id,
              post.isLiked,
              post.likesCount,
            );
      }
    });

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SocialPost(
          userId: post.user.id,
          userName: post.user.displayName,
          userAvatarUrl: post.user.avatarUrl,
          content: post.content,
          imageUrl: post.imageUrl,
          likesCount: likesCount,
          commentsCount: post.commentsCount,
          sharesCount: post.sharesCount,
          isLiked: isLiked,
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

            final success =
                await ref.read(likesProvider.notifier).toggleLike(post.id);
            if (success && context.mounted) {
              ref.read(feedProvider.notifier).updatePostLike(
                    post.id,
                    ref.read(likesProvider).isLiked(post.id),
                    ref.read(likesProvider).getLikeCount(post.id),
                  );
            }
            return success;
          },
          onComment: () => context.push('/post/${post.id}/comments'),
          onShare: () {},
        ),
      ),
    );
  }
}

class _BrutalistHeader extends StatelessWidget {
  final bool isDark;

  const _BrutalistHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceDark : AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainer,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Icon(
              Icons.notifications_outlined,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              size: 24,
            ),
          ),
          Text(
            'FREEBAY',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.primaryContainer,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateComposerSheet extends StatelessWidget {
  final bool isDark;

  const _CreateComposerSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'O QUE VOCE QUER CRIAR?',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.white : AppColors.onSurface,
              ),
            ),
          ),
          _CreateComposerOption(
            isDark: isDark,
            icon: Icons.forum_outlined,
            title: 'Post social',
            subtitle: 'Publicacoes, opinioes e interacoes para o feed.',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/create-post');
            },
          ),
          _CreateComposerOption(
            isDark: isDark,
            icon: Icons.sell_outlined,
            title: 'Anuncio de venda',
            subtitle: 'Item para catalogo com preco, categoria e imagem.',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/create-product');
            },
          ),
        ],
      ),
    );
  }
}

class _CreateComposerOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateComposerOption({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceContainerLowest,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              color: AppColors.primaryContainer,
              child: Icon(icon, color: AppColors.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, color: AppColors.primaryContainer),
          ],
        ),
      ),
    );
  }
}

class _FeedContentFilterBar extends StatelessWidget {
  final FeedContentFilter currentFilter;
  final ValueChanged<FeedContentFilter> onChanged;
  final bool isDark;

  const _FeedContentFilterBar({
    required this.currentFilter,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FeedFilterChip(
          label: 'Tudo',
          selected: currentFilter == FeedContentFilter.all,
          isDark: isDark,
          onTap: () => onChanged(FeedContentFilter.all),
        ),
        _FeedFilterChip(
          label: 'Social',
          selected: currentFilter == FeedContentFilter.socialOnly,
          isDark: isDark,
          onTap: () => onChanged(FeedContentFilter.socialOnly),
        ),
        _FeedFilterChip(
          label: 'Vendas',
          selected: currentFilter == FeedContentFilter.sellingOnly,
          isDark: isDark,
          onTap: () => onChanged(FeedContentFilter.sellingOnly),
        ),
      ],
    );
  }
}

class _FeedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FeedFilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brutalistGradient : null,
          color: selected
              ? null
              : (isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLowest),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: selected
                ? AppColors.onPrimary
                : (isDark ? AppColors.white : AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}

class _FeedTypeDropdown extends StatelessWidget {
  final FeedType currentType;
  final ValueChanged<FeedType> onChanged;
  final bool isDark;

  const _FeedTypeDropdown({
    required this.currentType,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FeedType>(
      initialValue: currentType,
      onSelected: onChanged,
      offset: const Offset(0, 32),
      color: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.onSurface, width: 2),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: FeedType.explore,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.explore,
                size: 16,
                color: currentType == FeedType.explore
                    ? AppColors.primaryContainer
                    : AppColors.outline,
              ),
              Freebay.horizontalSpacing8,
              Text(
                'EXPLORE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentType == FeedType.explore
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: FeedType.following,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: currentType == FeedType.following
                    ? AppColors.primaryContainer
                    : AppColors.outline,
              ),
              Freebay.horizontalSpacing8,
              Text(
                'FOLLOWING',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentType == FeedType.following
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentType == FeedType.explore ? Icons.explore : Icons.people,
              size: 14,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              currentType == FeedType.explore ? 'EXPLORE' : 'FOLLOWING',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color:
                    isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 14,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
