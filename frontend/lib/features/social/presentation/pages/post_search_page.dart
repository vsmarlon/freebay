import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/social_post.dart';
import '../providers/post_search_provider.dart';
import '../providers/user_search_provider.dart';

class PostSearchPage extends ConsumerStatefulWidget {
  const PostSearchPage({super.key});

  @override
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(postSearchProvider.notifier).search(
            query: query,
            filter: _selectedFilter,
            refresh: true,
          );
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    ref.read(postSearchProvider.notifier).search(
          query: _searchController.text,
          filter: filter,
          refresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(postSearchProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Buscar Posts',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar posts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(postSearchProvider.notifier).search(
                                query: '',
                                filter: _selectedFilter,
                                refresh: true,
                              );
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchDebounced,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  isSelected: _selectedFilter == 'all',
                  onSelected: () => _onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Seguindo',
                  isSelected: _selectedFilter == 'following',
                  onSelected: () => _onFilterChanged('following'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Seguidores',
                  isSelected: _selectedFilter == 'followers',
                  onSelected: () => _onFilterChanged('followers'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(searchState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PostSearchState state, bool isDark) {
    if (state.posts.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum post encontrado',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            state.hasMore &&
            !state.isLoading) {
          ref.read(postSearchProvider.notifier).search(
                query: state.query,
                filter: state.filter,
              );
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.posts.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = state.posts[index];
          final likesCount = post.isLiked ? post.likesCount : post.likesCount;
          final isLiked = post.isLiked;
          return SocialPost(
            userId: post.user.id,
            userName: post.user.displayName,
            userAvatarUrl: post.user.avatarUrl,
            content: post.content,
            imageUrl: post.imageUrl,
            likesCount: likesCount,
            commentsCount: post.commentsCount,
            sharesCount: post.sharesCount,
            isLiked: isLiked,
            price: post.product?.price.toDouble(),
            onTap: () => context.push('/post/${post.id}'),
            onUserTap: () => context.push('/user/${post.user.id}'),
            onLike: () async {
              final repo = ref.read(socialRepositoryProvider);
              if (post.isLiked) {
                await repo.unlikePost(post.id);
              } else {
                await repo.likePost(post.id);
              }
              ref.read(postSearchProvider.notifier).search(
                    query: state.query,
                    filter: state.filter,
                    refresh: true,
                  );
              return true;
            },
            onComment: () => context.push('/post/${post.id}/comments'),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : (isDark ? AppColors.mediumGray : AppColors.lightGray),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primaryPurple
                : (isDark ? AppColors.white : AppColors.darkGray),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
