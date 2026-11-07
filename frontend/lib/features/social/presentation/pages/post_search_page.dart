import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PostSearchPage extends ConsumerStatefulWidget {
  const PostSearchPage({super.key});

  @override
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final _searchController = TextEditingController();
  PostSearchFilter _selectedFilter = PostSearchFilter.all;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final previous = ref.read(postSearchProvider);
    _searchController.text = previous.query;
    _selectedFilter = previous.filter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(postSearchProvider.notifier)
          .search(query: query, filter: _selectedFilter, refresh: true);
    });
  }

  void _onFilterChanged(PostSearchFilter filter) {
    _debounceTimer?.cancel();
    setState(() {
      _selectedFilter = filter;
    });
    ref
        .read(postSearchProvider.notifier)
        .search(query: _searchController.text, filter: filter, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final searchState = ref.watch(postSearchProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(text: strings.feedSearchHint.toUpperCase()),
            BrutalistBreadcrumb(
              items: [
                BreadcrumbItem(
                  label: strings.feedTitle,
                  onTap: () => context.pop(),
                ),
                BreadcrumbItem(label: strings.commonSearch),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _searchController,
                hint: strings.feedSearchHint,
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty
                    ? BrutalistIconButton(
                        icon: Icons.clear,
                        semanticLabel: strings.commonClear,
                        onTap: () {
                          _debounceTimer?.cancel();
                          _searchController.clear();
                          ref
                              .read(postSearchProvider.notifier)
                              .search(
                                query: '',
                                filter: _selectedFilter,
                                refresh: true,
                              );
                        },
                      )
                    : null,
                onChanged: (query) {
                  setState(() {});
                  _onSearchDebounced(query);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BrutalistFilterChip(
                    label: strings.feedFilterAll,
                    selected: _selectedFilter == PostSearchFilter.all,
                    onTap: () => _onFilterChanged(PostSearchFilter.all),
                  ),
                  BrutalistFilterChip(
                    label: strings.feedFilterFollowing,
                    selected: _selectedFilter == PostSearchFilter.following,
                    onTap: () => _onFilterChanged(PostSearchFilter.following),
                  ),
                  BrutalistFilterChip(
                    label: strings.feedFilterFollowers,
                    selected: _selectedFilter == PostSearchFilter.followers,
                    onTap: () => _onFilterChanged(PostSearchFilter.followers),
                  ),
                ],
              ),
            ),
            Spacing.vMd,
            Expanded(child: _buildContent(context, searchState)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PostSearchState state) {
    if (state.error != null && state.posts.isEmpty && !state.isLoading) {
      return EmptyState.error(
        message: state.error,
        onRetry: () => ref
            .read(postSearchProvider.notifier)
            .search(query: state.query, filter: state.filter, refresh: true),
      );
    }
    if (state.posts.isEmpty && !state.isLoading) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n(context).feedNoResults,
        subtitle: l10n(context).feedNoResultsBody,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            state.hasMore &&
            !state.isLoading &&
            state.error == null) {
          ref
              .read(postSearchProvider.notifier)
              .search(query: state.query, filter: state.filter);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref
            .read(postSearchProvider.notifier)
            .search(query: state.query, filter: state.filter, refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.posts.length + (state.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerBlock(height: 80),
              );
            }

            final post = state.posts[index];
            return FeedPostItem(key: ValueKey(post.id), post: post);
          },
        ),
      ),
    );
  }
}
