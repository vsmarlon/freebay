import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/user_search_list.dart';
import 'package:freebay/features/social/presentation/widgets/suggestions_section.dart';

class PeopleSearchPage extends ConsumerStatefulWidget {
  const PeopleSearchPage({super.key});

  @override
  ConsumerState<PeopleSearchPage> createState() => _PeopleSearchPageState();
}

class _PeopleSearchPageState extends ConsumerState<PeopleSearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(suggestionsProvider.notifier).loadSuggestions();
    });
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
      ref.read(userSearchProvider.notifier).search(query: query, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);
    final query = _searchController.text;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'BUSCAR PESSOAS',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: 'Buscar por nome ou @username...',
              prefixIcon: Icons.search,
              onChanged: _onSearchDebounced,
              onFieldSubmitted: (_) {
                _debounceTimer?.cancel();
                ref
                    .read(userSearchProvider.notifier)
                    .search(query: _searchController.text, refresh: true);
              },
            ),
          ),
          Expanded(child: _buildContent(searchState, query)),
        ],
      ),
    );
  }

  Widget _buildContent(UserSearchState searchState, String query) {
    if (query.isEmpty && searchState.users.isEmpty && !searchState.isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.person_search,
                    size: 64,
                    color: AppColors.mediumGray,
                  ),
                  Spacing.vMd,
                  Text(
                    'Busque por pessoas...',
                    style: TextStyle(color: AppColors.mediumGray, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SuggestionsSection(),
          ],
        ),
      );
    }

    return UserSearchList(
      users: searchState.users,
      isLoading: searchState.isLoading,
      onLoadMore: () {
        if (searchState.hasMore && !searchState.isLoading) {
          ref
              .read(userSearchProvider.notifier)
              .search(query: _searchController.text);
        }
      },
      onFollow: (userId) async {
        await ref.read(socialRepositoryProvider).followUser(userId);
      },
      onUnfollow: (userId) async {
        await ref.read(socialRepositoryProvider).unfollowUser(userId);
      },
    );
  }
}
