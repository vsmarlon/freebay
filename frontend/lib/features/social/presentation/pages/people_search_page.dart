import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/widgets/user_search_list.dart';
import 'package:freebay/features/social/presentation/widgets/suggestions_section.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    final strings = l10n(context);
    final searchState = ref.watch(userSearchProvider);
    final query = _searchController.text;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: strings.socialPeopleSearchTitle,
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              semanticLabel: strings.accessibilityBack,
              onTap: () => context.pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: strings.socialPeopleSearchHint,
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
          Expanded(child: _buildContent(context, searchState, query)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserSearchState searchState,
    String query,
  ) {
    if (query.isEmpty && searchState.users.isEmpty && !searchState.isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_search,
                    size: 64,
                    color: AppColors.mediumGray,
                  ),
                  Spacing.vMd,
                  Text(
                    l10n(context).socialPeopleSearchEmpty,
                    style: const TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SuggestionsSection(asSliver: false),
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
    );
  }
}
